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
            ['name' => 'Say Coffee', 'plan' => 'free']
        );
        app()->instance('tenant', $tenant);

        $category = Category::create(['name' => 'Minuman']);
        $menu = Menu::create([
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
