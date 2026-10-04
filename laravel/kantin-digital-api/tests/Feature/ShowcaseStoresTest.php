<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Menu;
use App\Models\Tenant;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ShowcaseStoresTest extends TestCase
{
    use RefreshDatabase;

    public function test_only_active_tenants_with_menus_are_shown_in_showcase(): void
    {
        // 1. Tenant dengan menu (harus tampil)
        $activeWithMenu = Tenant::create([
            'name' => 'Kopi Mantap',
            'subdomain' => 'kopimantap',
            'is_active' => true,
        ]);
        $cat1 = Category::create([
            'tenant_id' => $activeWithMenu->id,
            'name' => 'Kopi',
            'is_active' => true,
        ]);
        Menu::create([
            'tenant_id' => $activeWithMenu->id,
            'category_id' => $cat1->id,
            'code' => 'KOP01',
            'name' => 'Es Kopi Susu',
            'price' => 15000,
            'is_available' => true,
        ]);

        // 2. Tenant baru beli tapi BELUM ada menu (TIDAK boleh tampil)
        $newTenantNoMenu = Tenant::create([
            'name' => 'Resto Baru Buka',
            'subdomain' => 'restobaru',
            'is_active' => true,
        ]);

        // 3. Tenant non-aktif meskipun ada menu (TIDAK boleh tampil)
        $inactiveWithMenu = Tenant::create([
            'name' => 'Kedai Tutup',
            'subdomain' => 'kedaitutup',
            'is_active' => false,
        ]);
        Menu::create([
            'tenant_id' => $inactiveWithMenu->id,
            'category_id' => $cat1->id,
            'code' => 'KED01',
            'name' => 'Menu Rahasia',
            'price' => 10000,
            'is_available' => true,
        ]);

        // Test GET /api/showcase-stores
        $response = $this->getJson('/api/showcase-stores');
        $response->assertStatus(200);
        $response->assertJson([
            'status' => true,
            'total' => 1,
        ]);

        $data = $response->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals('kopimantap', $data[0]['subdomain']);
        $this->assertEquals('Kopi Mantap', $data[0]['name']);
        $this->assertEquals(1, $data[0]['menus_count']);

        // 4. Sekarang tenant baru menambahkan menu ke tokonya
        Menu::create([
            'tenant_id' => $newTenantNoMenu->id,
            'category_id' => $cat1->id,
            'code' => 'RES01',
            'name' => 'Nasi Goreng Spesial',
            'price' => 25000,
            'is_available' => true,
        ]);

        // Test GET lagi, otomatis terdaftar!
        $response2 = $this->getJson('/api/showcase-stores');
        $response2->assertStatus(200);
        $response2->assertJson([
            'status' => true,
            'total' => 2,
        ]);
        $subdomains = collect($response2->json('data'))->pluck('subdomain')->all();
        $this->assertContains('kopimantap', $subdomains);
        $this->assertContains('restobaru', $subdomains);
    }
}
