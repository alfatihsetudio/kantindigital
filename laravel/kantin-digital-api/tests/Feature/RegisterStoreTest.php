<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RegisterStoreTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_check_subdomain_availability(): void
    {
        $response = $this->getJson('/api/check-subdomain?subdomain=kedai-baru');

        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('available', true)
            ->assertJsonPath('subdomain', 'kedai-baru');
    }

    public function test_reserved_subdomain_is_unavailable(): void
    {
        $response = $this->getJson('/api/check-subdomain?subdomain=admin');

        $response->assertOk()
            ->assertJsonPath('available', false);
    }

    public function test_existing_subdomain_is_detected_as_unavailable(): void
    {
        Tenant::create([
            'name' => 'Kopi Kenangan Asli',
            'subdomain' => 'kopi-kenangan',
            'is_active' => true,
        ]);

        $response = $this->getJson('/api/check-subdomain?subdomain=kopi-kenangan');

        $response->assertOk()
            ->assertJsonPath('status', true)
            ->assertJsonPath('available', false)
            ->assertJsonPath('subdomain', 'kopi-kenangan');
        $this->assertStringContainsString('sudah digunakan', $response->json('message'));
    }

    public function test_short_subdomain_is_unavailable(): void
    {
        $response = $this->getJson('/api/check-subdomain?subdomain=ab');

        $response->assertOk()
            ->assertJsonPath('available', false);
    }

    public function test_can_register_and_activate_new_store(): void
    {
        $payload = [
            'store_name' => 'Kedai Kopi Santai',
            'subdomain' => 'kopi-santai',
            'owner_name' => 'Budi Santoso',
            'owner_email' => 'budi.santai@example.com',
            'whatsapp' => '081234567890',
            'password' => 'password123',
            'plan' => 'pro',
            'payment_method' => 'qris',
            'address' => 'Jl. Kenanga No. 12',
            'category_type' => 'Kafe & Kopi',
        ];

        $response = $this->postJson('/api/register-store', $payload);

        $response->assertStatus(201)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.store_name', 'Kedai Kopi Santai')
            ->assertJsonPath('data.subdomain', 'kopi-santai')
            ->assertJsonPath('data.store_url', 'https://kopi-santai.ekasir.my.id');

        $this->assertDatabaseHas('tenants', [
            'name' => 'Kedai Kopi Santai',
            'subdomain' => 'kopi-santai',
        ]);

        $this->assertDatabaseHas('users', [
            'name' => 'Budi Santoso',
            'email' => 'budi.santai@example.com',
            'role' => 'admin',
        ]);
    }

    public function test_can_register_starter_and_pro_plans_with_qris(): void
    {
        // 1. Test Starter Plan (Rp 99.000)
        $resStarter = $this->postJson('/api/register-store', [
            'store_name' => 'Kedai Starter Baru',
            'subdomain' => 'kedai-starter',
            'owner_name' => 'Owner Starter',
            'owner_email' => 'starter@example.com',
            'whatsapp' => '081234567891',
            'password' => 'password123',
            'plan' => 'starter',
        ]);

        $resStarter->assertStatus(201)
            ->assertJsonPath('data.invoice.amount', 99000)
            ->assertJsonPath('data.invoice.plan', 'starter')
            ->assertJsonPath('data.invoice.payment_method', 'qris')
            ->assertJsonStructure(['data' => ['qris' => ['merchant_name', 'merchant_city', 'payload', 'amount']]]);

        // 2. Test Pro Plan (Rp 199.000)
        $resPro = $this->postJson('/api/register-store', [
            'store_name' => 'Resto Pro VIP',
            'subdomain' => 'resto-pro',
            'owner_name' => 'Owner Pro',
            'owner_email' => 'pro@example.com',
            'whatsapp' => '081234567892',
            'password' => 'password123',
            'plan' => 'pro',
        ]);

        $resPro->assertStatus(201)
            ->assertJsonPath('data.invoice.amount', 199000)
            ->assertJsonPath('data.invoice.plan', 'pro')
            ->assertJsonPath('data.invoice.payment_method', 'qris')
            ->assertJsonStructure(['data' => ['qris' => ['merchant_name', 'merchant_city', 'payload', 'amount']]]);
    }
}
