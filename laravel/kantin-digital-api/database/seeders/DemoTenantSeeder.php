<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Menu;
use App\Models\QrisSetting;
use App\Models\Table;
use App\Models\Tenant;
use App\Models\Topping;
use Illuminate\Database\Seeder;

class DemoTenantSeeder extends Seeder
{
    public function run(): void
    {
        $tenant = Tenant::updateOrCreate(
            ['subdomain' => 'demo'],
            [
                'name' => 'DEMO RESTO & CAFE',
                'primary_color' => '#2563EB',
                'address' => 'Kawasan Bisnis Demo No. 88, Jakarta',
                'phone' => '081234567890',
                'whatsapp' => '6287771262100',
                'plan' => 'pro',
                'is_active' => true,
                'menu_code_prefix' => 'DEMO',
                'meta_title' => 'Demo eKasir - Self Order & POS Resto',
                'meta_description' => 'Simulasi Sistem Pemesanan Mandiri & Kasir POS',
            ]
        );

        $tenantId = $tenant->id;

        // Categories
        $categories = [
            'Makanan' => Category::withoutGlobalScopes()->updateOrCreate(
                ['name' => 'Makanan', 'tenant_id' => $tenantId],
                ['is_active' => true]
            ),
            'Kopi' => Category::withoutGlobalScopes()->updateOrCreate(
                ['name' => 'Kopi', 'tenant_id' => $tenantId],
                ['is_active' => true]
            ),
            'Non Kopi' => Category::withoutGlobalScopes()->updateOrCreate(
                ['name' => 'Non Kopi', 'tenant_id' => $tenantId],
                ['is_active' => true]
            ),
            'Snack & Dessert' => Category::withoutGlobalScopes()->updateOrCreate(
                ['name' => 'Snack & Dessert', 'tenant_id' => $tenantId],
                ['is_active' => true]
            ),
        ];

        // Menus
        $menus = [
            [
                'code' => '01',
                'name' => 'Nasi Goreng Wagyu Spesial',
                'category_id' => $categories['Makanan']->id,
                'price' => 38000,
                'image_url' => 'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&w=600&q=80',
                'description' => 'Nasi goreng harum rempah nusantara dengan potongan wagyu empuk, telur mata sapi, dan acar segar.',
                'is_available' => true,
            ],
            [
                'code' => '02',
                'name' => 'Smash Cheeseburger & Crispy Fries',
                'category_id' => $categories['Makanan']->id,
                'price' => 35000,
                'image_url' => 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=600&q=80',
                'description' => '100% daging sapi Australia juicy dengan double cheddar cheese lumer, saus spesial, dan selada renyah.',
                'is_available' => true,
            ],
            [
                'code' => '03',
                'name' => 'Beef Ramen Shoyu Komplit',
                'category_id' => $categories['Makanan']->id,
                'price' => 42000,
                'image_url' => 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=600&q=80',
                'description' => 'Mie kenyal kuah kaldu shoyu autentik dengan topping chashu beef lembut, ajitsuke tamago, nori, dan daun bawang.',
                'is_available' => true,
            ],
            [
                'code' => '07',
                'name' => 'Iced Kopi Susu Gula Aren Spesial',
                'category_id' => $categories['Kopi']->id,
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?auto=format&fit=crop&w=600&q=80',
                'description' => 'Espresso house blend arabica dipadukan susu creamy dingin dan legitnya gula aren organik pilihan.',
                'is_available' => true,
            ],
            [
                'code' => '08',
                'name' => 'Caramel Macchiato Double Shot',
                'category_id' => $categories['Kopi']->id,
                'price' => 24000,
                'image_url' => 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?auto=format&fit=crop&w=600&q=80',
                'description' => 'Kombinasi vanila segar, susu berbusa lembut, double shot espresso, dan topping saus karamel lezat.',
                'is_available' => true,
            ],
            [
                'code' => '11',
                'name' => 'Signature Dark Chocolate Fudge',
                'category_id' => $categories['Non Kopi']->id,
                'price' => 22000,
                'image_url' => 'https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?auto=format&fit=crop&w=600&q=80',
                'description' => 'Cokelat Belgia pekat kaya rasa berpadu susu segar dingin, nikmat, manis pas, dan tidak bikin eneg.',
                'is_available' => true,
            ],
            [
                'code' => '14',
                'name' => 'Truffle French Fries with Cheese Mayo',
                'category_id' => $categories['Snack & Dessert']->id,
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1576107232684-1279f3908594?auto=format&fit=crop&w=600&q=80',
                'description' => 'Kentang goreng impor garing harum aroma minyak truffle, disajikan dengan cocolan keju mayo gurih.',
                'is_available' => true,
            ],
        ];

        foreach ($menus as $m) {
            Menu::withoutGlobalScopes()->updateOrCreate(
                ['name' => $m['name'], 'tenant_id' => $tenantId],
                array_merge($m, ['tenant_id' => $tenantId])
            );
        }

        // Toppings
        $toppings = [
            ['name' => 'Extra Shot Espresso', 'price' => 5000],
            ['name' => 'Boba Pearl Kenyal', 'price' => 4000],
            ['name' => 'Keju Mozzarella Melt', 'price' => 6000],
            ['name' => 'Telur Mata Sapi Setengah Matang', 'price' => 5000],
            ['name' => 'Ekstra Sambal Matah', 'price' => 3000],
        ];

        foreach ($toppings as $top) {
            Topping::withoutGlobalScopes()->updateOrCreate(
                ['name' => $top['name'], 'tenant_id' => $tenantId],
                array_merge($top, ['tenant_id' => $tenantId])
            );
        }

        // Tables 01 to 10
        for ($i = 1; $i <= 10; $i++) {
            $code = str_pad((string)$i, 2, '0', STR_PAD_LEFT);
            Table::withoutGlobalScopes()->updateOrCreate(
                ['code' => $code, 'tenant_id' => $tenantId],
                ['tenant_id' => $tenantId, 'name' => 'Meja ' . $code, 'is_occupied' => in_array($i, [2, 4])]
            );
        }

        // Qris Setting
        if (class_exists(QrisSetting::class)) {
            QrisSetting::withoutGlobalScopes()->updateOrCreate(
                ['tenant_id' => $tenantId],
                [
                    'merchant_name' => 'DEMO RESTO & CAFE',
                    'merchant_city' => 'JAKARTA',
                    'whatsapp_number' => '6287771262100',
                    'base_payload' => '00020101021226680016ID.CO.QRIS.WWW01189360052300000000005204581253033605802ID5914DEMO RESTO CAFE6007JAKARTA61051234062070703A016304ABCD',
                    'is_active' => true,
                ]
            );
        }
    }
}
