<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Menu;
use App\Models\Topping;
use App\Support\StoreOpeningHours;
use Carbon\Carbon;
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

    public function test_customer_can_load_menu_toppings_without_staff_login(): void
    {
        $topping = Topping::create(['name' => 'Extra shot', 'price' => 2000]);
        $otherTopping = Topping::create(['name' => 'Jelly', 'price' => 1000]);
        $this->menu->toppings()->attach($topping->id, ['min' => 0, 'max' => 2]);

        $this->getJson("/api/menus/{$this->menu->id}/toppings")
            ->assertOk()
            ->assertJsonPath('data.0.id', $topping->id)
            ->assertJsonPath('data.0.max', 2)
            ->assertJsonMissing(['id' => $otherTopping->id]);
    }

    public function test_menu_note_options_are_public_and_optional_on_orders(): void
    {
        $this->menu->update([
            'note_options' => ['Simple Sirup', 'Palm Sugar'],
        ]);

        $this->getJson('/api/menus')
            ->assertOk()
            ->assertJsonPath('data.0.note_options', ['Simple Sirup', 'Palm Sugar']);

        $this->postJson('/api/orders', [
            'order_type' => 'pickup',
            'items' => [
                ['menu_id' => $this->menu->id, 'quantity' => 1],
            ],
        ])->assertCreated();

        $this->postJson('/api/orders', [
            'order_type' => 'pickup',
            'items' => [
                [
                    'menu_id' => $this->menu->id,
                    'quantity' => 1,
                    'notes' => 'Tanpa gula',
                ],
            ],
        ])->assertUnprocessable()
            ->assertJsonValidationErrors('items');
    }

    public function test_menu_note_options_can_be_saved_from_admin_menu_form_payload(): void
    {
        $response = $this->postJson('/api/menus', [
            'name' => 'Kopi Pilihan Gula',
            'category_id' => $this->menu->category_id,
            'price' => 15000,
            'note_options' => '["Simple Sirup","Palm Sugar"]',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.note_options', ['Simple Sirup', 'Palm Sugar']);

        $this->assertDatabaseHas('menus', [
            'id' => $response->json('data.id'),
            'note_options' => json_encode(['Simple Sirup', 'Palm Sugar']),
        ]);
    }

    public function test_menu_toppings_can_be_selected_from_admin_menu_form_payload(): void
    {
        $extraShot = Topping::create(['name' => 'Extra shot', 'price' => 2000]);
        $jelly = Topping::create(['name' => 'Jelly', 'price' => 1000]);

        $response = $this->postJson('/api/menus', [
            'name' => 'Kopi Topping Pilihan',
            'category_id' => $this->menu->category_id,
            'price' => 15000,
            'topping_ids' => json_encode([$extraShot->id, $jelly->id]),
        ]);

        $response->assertOk();

        $menuId = $response->json('data.id');
        $this->assertDatabaseHas('menu_toppings', [
            'menu_id' => $menuId,
            'topping_id' => $extraShot->id,
        ]);
        $this->assertDatabaseHas('menu_toppings', [
            'menu_id' => $menuId,
            'topping_id' => $jelly->id,
        ]);

        $this->getJson('/api/menus')
            ->assertOk()
            ->assertJsonFragment([
                'name' => 'Kopi Topping Pilihan',
                'topping_ids' => [$extraShot->id, $jelly->id],
            ]);
    }

    public function test_toppings_can_be_linked_to_multiple_categories(): void
    {
        $kopi = Category::create(['name' => 'Kopi']);
        $nonKopi = Category::create(['name' => 'Non Kopi']);

        $response = $this->postJson('/api/toppings', [
            'name' => 'Extra Syrup',
            'price' => 3000,
            'category_ids' => [$kopi->id, $nonKopi->id],
        ]);

        $response->assertOk()
            ->assertJsonPath('data.category_ids', [$kopi->id, $nonKopi->id]);

        $this->assertDatabaseHas('category_topping', [
            'category_id' => $kopi->id,
            'topping_id' => $response->json('data.id'),
        ]);
        $this->assertDatabaseHas('category_topping', [
            'category_id' => $nonKopi->id,
            'topping_id' => $response->json('data.id'),
        ]);

        $this->getJson("/api/toppings?category_id={$kopi->id}")
            ->assertOk()
            ->assertJsonFragment(['name' => 'Extra Syrup']);
    }

    public function test_order_applies_promo_and_charged_topping_quantity(): void
    {
        $topping = Topping::create(['name' => 'Extra shot', 'price' => 2000]);
        $this->menu->toppings()->attach($topping->id, ['min' => 0, 'max' => 3]);
        app()->instance('tenant', (object) [
            'id' => null,
            'opening_hours' => '08:00 - 22:00',
            'is_store_open' => true,
            'store_opened_at' => Carbon::parse('2026-10-05 08:00:00', 'Asia/Jakarta')->toIso8601String(),
            'promo_discount_percent' => 10,
            'promo_scope' => 'all',
            'promo_menu_ids' => [],
        ]);
        Carbon::setTestNow(Carbon::parse('2026-10-05 10:00:00', 'Asia/Jakarta'));

        try {
            $response = $this->postJson('/api/orders', [
                'order_type' => 'pickup',
                'items' => [[
                    'menu_id' => $this->menu->id,
                    'quantity' => 2,
                    'toppings' => [[
                        'topping_id' => $topping->id,
                        'quantity' => 2,
                    ]],
                ]],
            ]);
        } finally {
            Carbon::setTestNow();
        }

        $response->assertCreated();
        $this->assertDatabaseHas('orders', [
            'total_amount' => 13000,
            'discount_amount' => 1000,
        ]);
        $orderCode = $response->json('data.code');
        $this->getJson("/api/orders/{$orderCode}")
            ->assertOk()
            ->assertJsonPath('data.total_amount', 13000)
            ->assertJsonPath('data.discount_amount', 1000)
            ->assertJsonPath('data.qris.amount', 13000);
        $this->assertDatabaseHas('order_items', [
            'price' => 5000,
            'quantity' => 2,
            'discount_amount' => 1000,
        ]);
        $this->assertDatabaseHas('order_item_toppings', [
            'topping_id' => $topping->id,
            'quantity' => 2,
        ]);
    }

    public function test_selected_menu_promo_does_not_discount_other_menu_items(): void
    {
        $otherMenu = Menu::create([
            'category_id' => $this->menu->category_id,
            'name' => 'Kopi Susu',
            'price' => 3000,
        ]);
        app()->instance('tenant', (object) [
            'id' => null,
            'opening_hours' => '08:00 - 22:00',
            'is_store_open' => true,
            'store_opened_at' => Carbon::parse('2026-10-05 08:00:00', 'Asia/Jakarta')->toIso8601String(),
            'promo_discount_percent' => 10,
            'promo_scope' => 'selected',
            'promo_menu_ids' => [$this->menu->id],
        ]);
        Carbon::setTestNow(Carbon::parse('2026-10-05 10:00:00', 'Asia/Jakarta'));

        try {
            $this->postJson('/api/orders', [
                'order_type' => 'pickup',
                'items' => [
                    ['menu_id' => $this->menu->id, 'quantity' => 1],
                    ['menu_id' => $otherMenu->id, 'quantity' => 1],
                ],
            ])->assertCreated();
        } finally {
            Carbon::setTestNow();
        }

        $this->assertDatabaseHas('orders', [
            'total_amount' => 7500,
            'discount_amount' => 500,
        ]);
    }

    public function test_public_order_is_rejected_when_store_is_closed(): void
    {
        app()->instance('tenant', (object) [
            'id' => null,
            'opening_hours' => '08:00 - 22:00',
            'is_store_open' => true,
            'store_opened_at' => Carbon::parse('2026-10-05 08:00:00', 'Asia/Jakarta')->toIso8601String(),
        ]);
        Carbon::setTestNow(Carbon::parse('2026-10-05 22:00:00', 'Asia/Jakarta'));

        try {
            $this->postJson('/api/orders', [
                'order_type' => 'pickup',
                'items' => [
                    [
                        'menu_id' => $this->menu->id,
                        'quantity' => 1,
                        'topping_ids' => [],
                    ],
                ],
            ])->assertUnprocessable()
                ->assertJsonPath(
                    'message',
                    'Toko sedang di luar jam operasional. Jam buka: 08:00 - 22:00.'
                );
        } finally {
            Carbon::setTestNow();
        }

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_public_order_is_rejected_until_a_staff_member_opens_the_store(): void
    {
        $tenant = new \App\Models\Tenant([
            'opening_hours' => '08:00 - 22:00',
            'is_store_open' => false,
        ]);
        $tenant->store_opened_at = null;
        app()->instance('tenant', $tenant);
        Carbon::setTestNow(Carbon::parse('2026-10-05 10:00:00', 'Asia/Jakarta'));

        try {
            $this->postJson('/api/orders', [
                'order_type' => 'pickup',
                'items' => [
                    [
                        'menu_id' => $this->menu->id,
                        'quantity' => 1,
                        'topping_ids' => [],
                    ],
                ],
            ])->assertUnprocessable()
                ->assertJsonPath(
                    'message',
                    'Mohon maaf yang sebesar-besarnya, saat ini toko kami belum dapat melayani pesanan sebagaimana mestinya karena ada kendala operasional yang sedang kami tangani. Jadwal operasional: 08:00 - 22:00. Silakan tunggu toko buka kembali.'
                );
        } finally {
            Carbon::setTestNow();
        }

        $this->assertDatabaseCount('orders', 0);
    }

    public function test_opening_hours_support_weekdays_and_reject_invalid_schedules(): void
    {
        $mondayMorning = Carbon::parse('2026-10-05 09:00:00', 'Asia/Jakarta');
        $sundayMorning = Carbon::parse('2026-10-04 09:00:00', 'Asia/Jakarta');

        $this->assertTrue(StoreOpeningHours::isOpen(
            'Senin-Sabtu 08:00-22:00; Minggu tutup',
            $mondayMorning
        ));
        $this->assertFalse(StoreOpeningHours::isOpen(
            'Senin-Sabtu 08:00-22:00; Minggu tutup',
            $sundayMorning
        ));
        $openedAt = Carbon::parse('2026-10-05 08:00:00', 'Asia/Jakarta')
            ->toIso8601String();
        $this->assertTrue(StoreOpeningHours::wasOpenedDuringCurrentWindow(
            '08:00 - 22:00',
            $openedAt,
            Carbon::parse('2026-10-05 09:00:00', 'Asia/Jakarta')
        ));
        $this->assertFalse(StoreOpeningHours::wasOpenedDuringCurrentWindow(
            '08:00 - 22:00',
            $openedAt,
            Carbon::parse('2026-10-06 09:00:00', 'Asia/Jakarta')
        ));
        $this->assertFalse(StoreOpeningHours::isValid('jam bebas'));
    }

    public function test_opening_hours_use_jakarta_timezone_and_updated_closing_time(): void
    {
        $this->assertSame('Asia/Jakarta', config('app.timezone'));
        Carbon::setTestNow(Carbon::parse('2026-10-05 22:59:00', 'Asia/Jakarta'));

        try {
            $this->assertTrue(StoreOpeningHours::isOpen('Setiap hari, 09:30 - 23:00'));
            Carbon::setTestNow(Carbon::parse('2026-10-05 23:00:00', 'Asia/Jakarta'));
            $this->assertFalse(StoreOpeningHours::isOpen('Setiap hari, 09:30 - 23:00'));
        } finally {
            Carbon::setTestNow();
        }
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
