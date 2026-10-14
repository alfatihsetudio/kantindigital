<?php

namespace Tests\Feature;

use App\Models\CashierShiftReport;
use App\Models\Category;
use App\Models\Menu;
use App\Models\Order;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class CashierShiftReportTest extends TestCase
{
    use RefreshDatabase;

    private Tenant $tenant;
    private User $admin;
    private User $cashier;
    private Menu $menu;

    protected function setUp(): void
    {
        parent::setUp();

        $this->tenant = Tenant::create([
            'subdomain' => 'testshift',
            'name' => 'Kantin Shift Test',
            'opening_hours' => '08:00 - 22:00',
            'is_store_open' => true,
            'store_opened_at' => now()->startOfDay()->toIso8601String(),
        ]);

        app()->instance('tenant', $this->tenant);

        $this->admin = User::factory()->create([
            'tenant_id' => $this->tenant->id,
            'role' => 'admin',
        ]);

        $this->cashier = User::factory()->create([
            'tenant_id' => $this->tenant->id,
            'role' => 'cashier',
        ]);

        $category = Category::create([
            'tenant_id' => $this->tenant->id,
            'name' => 'Makanan',
            'is_active' => true,
        ]);

        $this->menu = Menu::create([
            'tenant_id' => $this->tenant->id,
            'category_id' => $category->id,
            'name' => 'Nasi Goreng',
            'price' => 20000,
            'is_available' => true,
        ]);
    }

    public function test_cashier_can_view_current_running_sales_accumulation(): void
    {
        // 1 cash order (20000) & 1 qris order (40000)
        Order::create([
            'tenant_id' => $this->tenant->id,
            'code' => 'ORD1',
            'status' => 'READY',
            'payment_method' => 'cash',
            'total_amount' => 20000,
        ]);

        Order::create([
            'tenant_id' => $this->tenant->id,
            'code' => 'ORD2',
            'status' => 'PROCESSING',
            'payment_method' => 'qris',
            'total_amount' => 40000,
        ]);

        // Unpaid order should not be counted in cash/qris expected
        Order::create([
            'tenant_id' => $this->tenant->id,
            'code' => 'ORD3',
            'status' => 'UNPAID',
            'payment_method' => 'cash',
            'total_amount' => 15000,
        ]);

        $response = $this->actingAs($this->cashier)
            ->getJson('/api/cashier/shift/current')
            ->assertOk();

        $response->assertJsonPath('data.total_orders', 2)
            ->assertJsonPath('data.total_cash_expected', 20000)
            ->assertJsonPath('data.total_qris_expected', 40000)
            ->assertJsonPath('data.total_sales_expected', 60000)
            ->assertJsonPath('data.unpaid_orders_count', 1);
    }

    public function test_cashier_can_submit_shift_report_and_orders_are_associated(): void
    {
        $order1 = Order::create([
            'tenant_id' => $this->tenant->id,
            'code' => 'ORD1',
            'status' => 'SERVED',
            'payment_method' => 'cash',
            'total_amount' => 50000,
        ]);

        $response = $this->actingAs($this->cashier)
            ->postJson('/api/cashier/shift/submit', [
                'cash_received' => 50000,
                'cashier_notes' => 'Uang pas',
            ])
            ->assertCreated();

        $reportId = $response->json('data.id');

        $this->assertDatabaseHas('cashier_shift_reports', [
            'id' => $reportId,
            'status' => 'PENDING',
            'total_orders' => 1,
            'total_cash_expected' => 50000,
            'cash_received' => 50000,
            'cash_difference' => 0,
        ]);

        $this->assertEquals($reportId, $order1->fresh()->cashier_shift_report_id);

        // Current shift should now have 0 orders
        $this->actingAs($this->cashier)
            ->getJson('/api/cashier/shift/current')
            ->assertJsonPath('data.total_orders', 0)
            ->assertJsonPath('data.total_sales_expected', 0);
    }

    public function test_admin_can_approve_cashier_shift_report(): void
    {
        $report = CashierShiftReport::create([
            'tenant_id' => $this->tenant->id,
            'cashier_id' => $this->cashier->id,
            'shift_opened_at' => now(),
            'shift_closed_at' => now(),
            'total_orders' => 2,
            'total_cash_expected' => 100000,
            'total_qris_expected' => 50000,
            'total_sales_expected' => 150000,
            'cash_received' => 100000,
            'cash_difference' => 0,
            'status' => 'PENDING',
        ]);

        $this->actingAs($this->admin)
            ->postJson("/api/cashier/shift/reports/{$report->id}/approve", [
                'notes' => 'Cocok dan disetujui.',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'APPROVED');

        $this->assertDatabaseHas('cashier_shift_reports', [
            'id' => $report->id,
            'status' => 'APPROVED',
            'approved_by' => $this->admin->id,
            'approval_notes' => 'Cocok dan disetujui.',
        ]);
    }

    public function test_admin_can_reject_cashier_shift_report_and_orders_are_unlinked(): void
    {
        $report = CashierShiftReport::create([
            'tenant_id' => $this->tenant->id,
            'cashier_id' => $this->cashier->id,
            'shift_opened_at' => now(),
            'shift_closed_at' => now(),
            'total_orders' => 1,
            'total_cash_expected' => 50000,
            'total_qris_expected' => 0,
            'total_sales_expected' => 50000,
            'cash_received' => 40000,
            'cash_difference' => -10000,
            'status' => 'PENDING',
        ]);

        $order = Order::create([
            'tenant_id' => $this->tenant->id,
            'code' => 'ORD99',
            'status' => 'SERVED',
            'payment_method' => 'cash',
            'total_amount' => 50000,
            'cashier_shift_report_id' => $report->id,
        ]);

        $this->actingAs($this->admin)
            ->postJson("/api/cashier/shift/reports/{$report->id}/reject", [
                'notes' => 'Selisih kurang Rp 10.000, tolong periksa laci kasir.',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'REJECTED');

        $this->assertNull($order->fresh()->cashier_shift_report_id);
    }
}
