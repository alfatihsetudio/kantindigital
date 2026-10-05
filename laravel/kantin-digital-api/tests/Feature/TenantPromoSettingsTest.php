<?php

namespace Tests\Feature;

use App\Models\Tenant;
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
        ])->assertOk()
            ->assertJsonPath('data.promo_badge_text', 'Promo Akhir Pekan')
            ->assertJsonPath('data.promo_message', 'Beli dua gratis satu!');

        $this->getJson('/api/tenant/info')
            ->assertOk()
            ->assertJsonPath('data.promo_badge_text', 'Promo Akhir Pekan')
            ->assertJsonPath('data.promo_message', 'Beli dua gratis satu!');

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'promo_badge_text' => 'Promo Akhir Pekan',
            'promo_message' => 'Beli dua gratis satu!',
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
}
