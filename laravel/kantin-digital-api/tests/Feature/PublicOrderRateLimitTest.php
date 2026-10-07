<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Menu;
use App\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PublicOrderRateLimitTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_order_endpoint_limits_requests_per_tenant_and_ip(): void
    {
        $tenant = Tenant::firstOrCreate(
            ['subdomain' => 'saycoffee'],
            [
                'name' => 'Say Coffee',
                'plan' => 'free',
                'is_active' => true,
                'is_store_open' => true,
                'opening_hours' => '00:00 - 23:59',
                'store_opened_at' => now()->startOfDay()->toIso8601String(),
            ]
        );
        $tenant->update([
            'is_active' => true,
            'is_store_open' => true,
            'opening_hours' => '00:00 - 23:59',
            'store_opened_at' => now()->startOfDay()->toIso8601String(),
        ]);
        app()->instance('tenant', $tenant);

        $category = Category::create([
            'tenant_id' => $tenant->id,
            'name' => 'Minuman',
        ]);
        $menu = Menu::create([
            'tenant_id' => $tenant->id,
            'category_id' => $category->id,
            'name' => 'Es Teh',
            'price' => 5000,
        ]);

        $payload = [
            'order_type' => 'pickup',
            'items' => [
                [
                    'menu_id' => $menu->id,
                    'quantity' => 1,
                    'topping_ids' => [],
                ],
            ],
        ];

        for ($attempt = 0; $attempt < 5; $attempt++) {
            $this->withHeader('Host', 'saycoffee.example.test')
                ->postJson('/api/orders', $payload)
                ->assertCreated();
        }

        $this->withHeader('Host', 'saycoffee.example.test')
            ->postJson('/api/orders', $payload)
            ->assertTooManyRequests();

        $this->assertDatabaseCount('orders', 5);

        for ($batch = 0; $batch < 5; $batch++) {
            $this->travel(61)->seconds();

            for ($attempt = 0; $attempt < 5; $attempt++) {
                $this->withHeader('Host', 'saycoffee.example.test')
                    ->postJson('/api/orders', $payload)
                    ->assertCreated();
            }
        }

        $this->travel(61)->seconds();
        $this->withHeader('Host', 'saycoffee.example.test')
            ->postJson('/api/orders', $payload)
            ->assertTooManyRequests();

        $this->assertDatabaseCount('orders', 30);
    }
}
