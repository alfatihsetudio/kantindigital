<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Menu;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OnlineOrderTest extends TestCase
{
    use RefreshDatabase;

    private Menu $menu;

    protected function setUp(): void
    {
        parent::setUp();

        $this->withoutMiddleware();

        $category = Category::create(['name' => 'Minuman']);
        $this->menu = Menu::create([
            'category_id' => $category->id,
            'name' => 'Es Teh',
            'price' => 5000,
        ]);
    }

    public function test_delivery_order_is_created_without_a_table(): void
    {
        $response = $this->postJson('/api/orders', [
            'order_type' => 'delivery',
            'delivery_address' => 'Jl. Merdeka No. 10',
            'customer_name' => 'Pelanggan',
            'customer_phone' => '081234567890',
            'items' => [
                [
                    'menu_id' => $this->menu->id,
                    'quantity' => 2,
                    'topping_ids' => [],
                ],
            ],
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('orders', [
            'order_type' => 'delivery',
            'delivery_address' => 'Jl. Merdeka No. 10',
            'table_id' => null,
        ]);
    }

    public function test_delivery_order_requires_an_address(): void
    {
        $response = $this->postJson('/api/orders', [
            'order_type' => 'delivery',
            'customer_name' => 'Pelanggan',
            'customer_phone' => '081234567890',
            'items' => [
                [
                    'menu_id' => $this->menu->id,
                    'quantity' => 1,
                    'topping_ids' => [],
                ],
            ],
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('delivery_address');
        $this->assertDatabaseCount('orders', 0);
    }
}
