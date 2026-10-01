<?php

namespace Tests\Feature;

use App\Models\Tenant;
use App\Models\Menu;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\MenuSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SuperAdminAccessTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->withServerVariables(['HTTP_HOST' => 'kantindigital.test']);
    }

    public function test_superadmin_can_list_and_create_tenants(): void
    {
        Sanctum::actingAs(User::create([
            'name' => 'Platform Admin',
            'email' => 'platform@example.test',
            'password' => 'a-long-password',
            'role' => 'superadmin',
        ]));

        $response = $this->postJson('/api/superadmin/tenants', [
            'name' => 'Kantin Baru',
            'subdomain' => 'kantin-baru',
            'plan' => 'pro',
            'owner_name' => 'Pemilik Baru',
            'owner_email' => 'owner@example.test',
            'manager_name' => 'Manager',
            'manager_email' => 'manager@example.test',
            'cashier_name' => 'Kasir',
            'cashier_email' => 'cashier@example.test',
            'operations_name' => 'Operasional',
            'operations_email' => 'operations@example.test',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.subdomain', 'kantin-baru')
            ->assertJsonPath('data.users_count', 4)
            ->assertJsonPath('data.menus_count', count((new MenuSeeder())->templates()))
            ->assertJsonCount(4, 'initial_accounts');
        $this->assertDatabaseCount('categories', count((new CategorySeeder())->templates()));
        $this->assertDatabaseCount('menus', count((new MenuSeeder())->templates()));
        $this->assertDatabaseHas('menus', [
            'tenant_id' => $response->json('data.id'),
            'name' => 'Nasi Goreng Spesial',
            'price' => 25000,
            'image_url' => 'http://kantindigital.test/uploads/menu-templates/photo-1512058564366-18510be2db19.jpg',
            'is_available' => false,
        ]);
        $this->assertDatabaseMissing('menus', [
            'tenant_id' => $response->json('data.id'),
            'name' => 'SAY AREN',
        ]);
        foreach (Menu::where('tenant_id', $response->json('data.id'))->get() as $menu) {
            $this->assertStringContainsString('/uploads/menu-templates/', $menu->image_url);
            $this->assertFileExists(
                public_path('uploads/menu-templates/'.basename(parse_url($menu->image_url, PHP_URL_PATH)))
            );
        }
        foreach ([
            'owner@example.test' => 'admin',
            'manager@example.test' => 'manager',
            'cashier@example.test' => 'cashier',
            'operations@example.test' => 'operations',
        ] as $email => $role) {
            $this->assertDatabaseHas('users', [
                'email' => $email,
                'role' => $role,
                'must_change_password' => true,
            ]);
        }

        $this->getJson('/api/superadmin/tenants')
            ->assertOk()
            ->assertJsonPath(
                'data.0.menus_count',
                count((new MenuSeeder())->templates())
            );

        $ownerCredentials = $response->json('initial_accounts.0');
        $this->withHeader('X-Tenant', 'kantin-baru')
            ->postJson('/api/login', [
                'email' => $ownerCredentials['email'],
                'password' => $ownerCredentials['temporary_password'],
            ])->assertOk()
            ->assertJsonPath('data.user.must_change_password', true);
    }

    public function test_tenant_management_is_forbidden_to_non_superadmins(): void
    {
        Sanctum::actingAs(User::create([
            'name' => 'Tenant Admin',
            'email' => 'tenant-admin@example.test',
            'password' => 'a-long-password',
            'role' => 'admin',
        ]));

        $this->getJson('/api/superadmin/tenants')
            ->assertForbidden();
    }

    public function test_tenant_management_requires_authentication(): void
    {
        $this->getJson('/api/superadmin/tenants')
            ->assertUnauthorized();
    }

    public function test_platform_domain_does_not_expose_a_default_tenant(): void
    {
        Tenant::create([
            'name' => 'Private Tenant',
            'subdomain' => 'private-tenant',
            'plan' => 'free',
        ]);

        $this->getJson('/api/tenant/info')
            ->assertNotFound()
            ->assertJsonPath('message', 'Tenant tidak ditemukan');
    }

    public function test_superadmin_can_log_in_on_the_platform_domain(): void
    {
        User::create([
            'name' => 'Platform Admin',
            'email' => 'platform-login@example.test',
            'password' => 'a-long-password',
            'role' => 'superadmin',
        ]);

        $this->postJson('/api/login', [
            'email' => 'platform-login@example.test',
            'password' => 'a-long-password',
        ])->assertOk()
            ->assertJsonPath('data.user.role', 'superadmin');
    }

    public function test_browser_origin_login_uses_bearer_token_auth_without_csrf_session(): void
    {
        User::create([
            'name' => 'Platform Admin',
            'email' => 'platform-browser-login@example.test',
            'password' => 'a-long-password',
            'role' => 'superadmin',
        ]);

        $this->withHeaders([
            'Origin' => 'http://kantindigital.test',
            'Referer' => 'http://kantindigital.test/#/admin/login',
        ])->postJson('/api/login', [
            'email' => 'platform-browser-login@example.test',
            'password' => 'a-long-password',
        ])->assertOk()
            ->assertJsonPath('data.user.role', 'superadmin');
    }

    public function test_superadmin_cannot_log_in_in_a_tenant_context(): void
    {
        Tenant::create([
            'name' => 'Tenant',
            'subdomain' => 'tenant',
            'plan' => 'free',
        ]);
        User::create([
            'name' => 'Platform Admin',
            'email' => 'platform-tenant-login@example.test',
            'password' => 'a-long-password',
            'role' => 'superadmin',
        ]);
        $this->withServerVariables([
            'HTTP_HOST' => 'tenant.kantindigital.test',
        ]);
        $this->withHeader('X-Tenant', 'tenant');

        $this->postJson('/api/login', [
            'email' => 'platform-tenant-login@example.test',
            'password' => 'a-long-password',
        ])->assertUnauthorized();
    }

    public function test_superadmin_can_update_platform_settings_but_other_roles_cannot(): void
    {
        $tenant = Tenant::create([
            'name' => 'Tenant',
            'subdomain' => 'tenant-settings',
            'plan' => 'free',
        ]);

        Sanctum::actingAs(User::create([
            'name' => 'Platform Admin',
            'email' => 'platform-settings@example.test',
            'password' => 'a-long-password',
            'role' => 'superadmin',
        ]));

        $this->putJson("/api/superadmin/tenants/{$tenant->id}", [
            'plan' => 'pro',
            'is_active' => false,
        ])->assertOk()
            ->assertJsonPath('data.plan', 'pro')
            ->assertJsonPath('data.is_active', false);

        $this->assertDatabaseHas('tenants', [
            'id' => $tenant->id,
            'is_active' => false,
        ]);
    }

    public function test_expired_tenant_cannot_access_tenant_routes(): void
    {
        Tenant::create([
            'name' => 'Expired Tenant',
            'subdomain' => 'expired-tenant',
            'plan' => 'free',
            'expires_at' => Carbon::yesterday(),
        ]);
        $this->withHeader('X-Tenant', 'expired-tenant');

        $this->getJson('/api/tenant/info')
            ->assertNotFound()
            ->assertJsonPath('status', false);
    }

    public function test_password_change_updates_only_the_authenticated_superadmin(): void
    {
        $superadmin = User::create([
            'name' => 'Platform Admin',
            'email' => 'platform-password@example.test',
            'password' => 'old-platform-password',
            'role' => 'superadmin',
        ]);
        $otherUser = User::create([
            'name' => 'Another User',
            'email' => 'other-password@example.test',
            'password' => 'other-user-password',
            'role' => 'superadmin',
        ]);
        Sanctum::actingAs($superadmin);

        $this->postJson('/api/change-password', [
            'user_id' => $otherUser->id,
            'current_password' => 'old-platform-password',
            'new_password' => 'new-platform-password',
        ])->assertOk();

        $this->assertTrue(Hash::check('new-platform-password', $superadmin->fresh()->password));
        $this->assertTrue(Hash::check('other-user-password', $otherUser->fresh()->password));
    }

    public function test_temporary_account_must_change_password_before_using_protected_routes(): void
    {
        $tenant = Tenant::create([
            'name' => 'Tenant Password Test',
            'subdomain' => 'tenant-password-test',
            'plan' => 'free',
        ]);
        $manager = User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Manager',
            'email' => 'manager-password-test@example.test',
            'password' => 'temporary-password',
            'role' => 'manager',
            'must_change_password' => true,
        ]);
        $this->withHeader('X-Tenant', $tenant->subdomain);
        Sanctum::actingAs($manager);

        $this->getJson('/api/users')
            ->assertStatus(423)
            ->assertJsonPath('must_change_password', true);

        $this->postJson('/api/change-password', [
            'current_password' => 'temporary-password',
            'new_password' => 'permanent-password',
        ])->assertOk();

        $this->assertFalse($manager->fresh()->must_change_password);
        $this->getJson('/api/users')->assertOk();
    }
}
