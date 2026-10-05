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
}
