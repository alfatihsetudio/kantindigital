<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\Category;
use App\Models\Menu;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantPromoSettingsTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutMiddleware();
    }

    public function test_tenant_promo_copy_can_be_updated_and_returned_by_tenant_info(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        app()->instance('tenant', $tenant);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'promo_badge_text' => 'Promo Akhir Pekan',
            'promo_message' => 'Beli dua gratis satu!',
            'promo_discount_percent' => 15,
            'promo_scope' => 'all',
            'promo_menu_ids' => [],
        ])->assertOk()
            ->assertJsonPath('data.promo_badge_text', 'Promo Akhir Pekan')
            ->assertJsonPath('data.promo_message', 'Beli dua gratis satu!')
            ->assertJsonPath('data.promo_discount_percent', 15)
            ->assertJsonPath('data.promo_scope', 'all');

        $this->getJson('/api/tenant/info')
            ->assertOk()
            ->assertJsonPath('data.promo_badge_text', 'Promo Akhir Pekan')
            ->assertJsonPath('data.promo_message', 'Beli dua gratis satu!')
            ->assertJsonPath('data.promo_discount_percent', 15);

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'promo_badge_text' => 'Promo Akhir Pekan',
            'promo_message' => 'Beli dua gratis satu!',
            'promo_discount_percent' => 15,
        ]);
    }

    public function test_tenant_opening_hours_can_be_updated_and_returned_by_tenant_info(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        app()->instance('tenant', $tenant);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'opening_hours' => 'Senin-Sabtu, 08:00 - 22:00',
        ])->assertOk()
            ->assertJsonPath('data.opening_hours', 'Senin-Sabtu, 08:00 - 22:00');

        $this->getJson('/api/tenant/info')
            ->assertOk()
            ->assertJsonPath('data.opening_hours', 'Senin-Sabtu, 08:00 - 22:00');

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'opening_hours' => 'Senin-Sabtu, 08:00 - 22:00',
        ]);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'opening_hours' => 'Setiap hari, 09:30 - 23:00',
        ])->assertOk()
            ->assertJsonPath('data.opening_hours', 'Setiap hari, 09:30 - 23:00');

        $this->getJson('/api/tenant/info')
            ->assertOk()
            ->assertJsonPath('data.opening_hours', 'Setiap hari, 09:30 - 23:00');

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'opening_hours' => 'Setiap hari, 09:30 - 23:00',
        ]);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'opening_hours' => 'Senin - Sabtu, 10:00 - 21:00; Minggu Tutup',
        ])->assertOk()
            ->assertJsonPath('data.opening_hours', 'Senin - Sabtu, 10:00 - 21:00; Minggu Tutup');

        $this->getJson('/api/tenant/info')
            ->assertOk()
            ->assertJsonPath('data.opening_hours', 'Senin - Sabtu, 10:00 - 21:00; Minggu Tutup');

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'opening_hours' => 'Senin - Sabtu, 10:00 - 21:00; Minggu Tutup',
        ]);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'opening_hours' => 'Senin, Selasa, Kamis, Jumat, 10:00 - 21:00; Rabu, Sabtu, Minggu Tutup',
        ])->assertOk()
            ->assertJsonPath('data.opening_hours', 'Senin, Selasa, Kamis, Jumat, 10:00 - 21:00; Rabu, Sabtu, Minggu Tutup');

        $this->getJson('/api/tenant/info')
            ->assertOk()
            ->assertJsonPath('data.opening_hours', 'Senin, Selasa, Kamis, Jumat, 10:00 - 21:00; Rabu, Sabtu, Minggu Tutup');

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'opening_hours' => 'Senin, Selasa, Kamis, Jumat, 10:00 - 21:00; Rabu, Sabtu, Minggu Tutup',
        ]);
    }

    public function test_invalid_tenant_opening_hours_are_rejected(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        app()->instance('tenant', $tenant);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'opening_hours' => 'jam bebas',
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('opening_hours');
    }

    public function test_selected_menu_promo_requires_and_persists_tenant_menus(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        app()->instance('tenant', $tenant);
        $category = Category::create([
            'tenant_id' => $tenant->id,
            'name' => 'Menu promo',
        ]);
        $menu = Menu::create([
            'tenant_id' => $tenant->id,
            'category_id' => $category->id,
            'name' => 'Menu diskon',
            'price' => 10000,
        ]);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'promo_discount_percent' => 20,
            'promo_scope' => 'selected',
            'promo_menu_ids' => [$menu->id],
        ])->assertOk()
            ->assertJsonPath('data.promo_scope', 'selected')
            ->assertJsonPath('data.promo_menu_ids.0', $menu->id);

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'promo_scope' => 'selected',
        ]);

        $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'promo_discount_percent' => 20,
            'promo_scope' => 'selected',
            'promo_menu_ids' => [],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('promo_menu_ids');
    }

    public function test_admin_or_cashier_can_open_and_close_store_during_opening_hours(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        $tenant->update([
            'opening_hours' => '08:00 - 22:00',
            'is_store_open' => false,
            'store_opened_at' => null,
        ]);
        app()->instance('tenant', $tenant);
        Carbon::setTestNow(Carbon::parse('2026-10-05 10:00:00', 'Asia/Jakarta'));

        try {
            $this->postJson('/api/tenant/store-status', [
                'is_store_open' => true,
            ])->assertOk()
                ->assertJsonPath('data.is_store_open', true);

            $this->getJson('/api/tenant/info')
                ->assertOk()
                ->assertJsonPath('data.is_store_open', true);

            $this->postJson('/api/tenant/store-status', [
                'is_store_open' => false,
            ])->assertOk()
                ->assertJsonPath('data.is_store_open', false);
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_admin_or_cashier_can_open_store_anytime_outside_opening_hours_or_on_holidays(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        $tenant->update([
            'opening_hours' => '08:00 - 22:00',
            'is_store_open' => false,
            'store_opened_at' => null,
        ]);
        app()->instance('tenant', $tenant);
        Carbon::setTestNow(Carbon::parse('2026-10-05 22:00:00', 'Asia/Jakarta'));

        try {
            $this->postJson('/api/tenant/store-status', [
                'is_store_open' => true,
            ])->assertOk()
                ->assertJsonPath('data.is_store_open', true);

            $this->getJson('/api/tenant/info')
                ->assertOk()
                ->assertJsonPath('data.is_store_open', true);
        } finally {
            Carbon::setTestNow();
        }

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'is_store_open' => true,
        ]);
    }

    public function test_tenant_meta_image_can_be_uploaded_and_compressed(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        app()->instance('tenant', $tenant);

        $image = \Illuminate\Http\UploadedFile::fake()->image('og_share.png', 1600, 1200);

        $response = $this->post('/api/tenant/update', [
            'name' => $tenant->name,
            'meta_title' => 'Say Coffee Juara',
            'meta_description' => 'Kopi terbaik untuk hari Anda.',
            'meta_image' => $image,
        ])->assertOk();

        $metaImageUrl = $response->json('data.meta_image');
        $this->assertNotNull($metaImageUrl);
        $this->assertStringContainsString('/uploads/meta/', $metaImageUrl);

        $storedFilename = basename(parse_url($metaImageUrl, PHP_URL_PATH));
        $storedPath = public_path('uploads/meta/'.$storedFilename);
        $this->assertFileExists($storedPath);

        // Check image was resized/compressed to <= 1200
        [$width, $height] = getimagesize($storedPath);
        $this->assertLessThanOrEqual(1200, $width);
        $this->assertLessThanOrEqual(1200, $height);

        // Cleanup test file
        if (file_exists($storedPath)) {
            unlink($storedPath);
        }
    }

    public function test_tenant_manifest_returns_tenant_name_and_logo(): void
    {
        $tenant = Tenant::create([
            'subdomain' => 'tokokopi',
            'name' => 'Toko Kopi Asik',
            'logo_url' => '/uploads/logos/kopi_logo.png',
            'is_active' => true,
        ]);

        $response = $this->get('http://tokokopi.example.test/manifest.json');

        $response->assertOk()
            ->assertJsonPath('name', 'Toko Kopi Asik')
            ->assertJsonPath('short_name', 'Toko Kopi Asik');

        $icons = $response->json('icons');
        $this->assertIsArray($icons);
        $this->assertNotEmpty($icons);
        $this->assertStringContainsString('kopi_logo.png', $icons[0]['src']);

        $apiResponse = $this->get('/api/manifest.json?tenant=tokokopi');
        $apiResponse->assertOk()
            ->assertJsonPath('name', 'Toko Kopi Asik')
            ->assertJsonPath('short_name', 'Toko Kopi Asik');

        $appManifestResponse = $this->get('/app-manifest.json?tenant=tokokopi');
        $appManifestResponse->assertOk()
            ->assertJsonPath('name', 'Toko Kopi Asik')
            ->assertJsonPath('short_name', 'Toko Kopi Asik');
    }

    public function test_safe_image_rule_rejects_oversized_and_invalid_extensions(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->firstOrFail();
        app()->instance('tenant', $tenant);

        // Test invalid extension
        $badFile = \Illuminate\Http\UploadedFile::fake()->create('malicious.pdf', 100);
        $response = $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'meta_image' => $badFile,
        ]);
        $response->assertStatus(422);

        // Test oversized file (> 5MB)
        $oversizedFile = \Illuminate\Http\UploadedFile::fake()->image('huge.jpg')->size(6000);
        $response = $this->postJson('/api/tenant/update', [
            'name' => $tenant->name,
            'meta_image' => $oversizedFile,
        ]);
        $response->assertStatus(422);
    }
}

