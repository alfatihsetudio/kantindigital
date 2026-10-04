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

    public function test_unavailable_menu_cannot_be_ordered(): void
    {
        $this->menu->update(['is_available' => false]);

        $response = $this->postJson('/api/orders', [
            'order_type' => 'pickup',
            'customer_name' => 'Pelanggan',
            'items' => [
                [
                    'menu_id' => $this->menu->id,
                    'quantity' => 1,
                    'topping_ids' => [],
                ],
            ],
        ]);

        $response->assertUnprocessable()
            ->assertJsonPath('message', 'Menu tidak tersedia: Es Teh');
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_order_item_limits_prevent_oversized_public_orders(): void
    {
        $response = $this->postJson('/api/orders', [
            'order_type' => 'pickup',
            'items' => array_fill(0, 21, [
                'menu_id' => $this->menu->id,
                'quantity' => 1,
                'topping_ids' => [],
            ]),
        ]);

        $response->assertUnprocessable()
            ->assertJsonValidationErrors('items');
        $this->assertDatabaseCount('orders', 0);
    }

    public function test_menu_availability_can_be_changed_through_the_api(): void
    {
        $response = $this->postJson('/api/menus', [
            'name' => 'Menu Musiman',
            'category_id' => $this->menu->category_id,
            'price' => 10000,
            'is_available' => false,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.is_available', false);
        $this->assertDatabaseHas('menus', [
            'name' => 'Menu Musiman',
            'is_available' => false,
        ]);
    }
}
