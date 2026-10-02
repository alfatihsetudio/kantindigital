<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use App\Models\Tenant;
use App\Models\Category;
use App\Models\Menu;
use App\Models\Topping;

return new class extends Migration
{
    public function up(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->first();
        if (!$tenant) {
            $tenantId = DB::table('tenants')->insertGetId([
                'subdomain' => 'saycoffee',
                'name' => 'SAY COFFEE',
                'primary_color' => '#6F4E37',
                'address' => 'Serang - Banten',
                'phone' => '08123456789',
                'whatsapp' => '6287771262100',
                'plan' => 'pro',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } else {
            $tenantId = $tenant->id;
        }

        // 1. Lepaskan menu makanan berat dari tenant Say Coffee
        DB::table('menus')->where('tenant_id', $tenantId)->delete();
        DB::table('categories')->where('tenant_id', $tenantId)->delete();
        DB::table('toppings')->where('tenant_id', $tenantId)->delete();

        // 2. Buat Kategori khusus Say Coffee: Kopi & Non-Kopi
        $catCoffeeId = DB::table('categories')->insertGetId([
            'tenant_id' => $tenantId,
            'name' => 'Kopi (Coffee)',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $catNonCoffeeId = DB::table('categories')->insertGetId([
            'tenant_id' => $tenantId,
            'name' => 'Non-Kopi (Non-Coffee)',
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 3. Masukkan Menu KOPI Say Coffee
        $coffeeMenus = [
            [
                'name' => 'Es Kopi Susu Gula Aren',
                'price' => 20000,
                'description' => 'Espresso house blend dipadu susu segar creamy dan gula aren organik pilihan.',
                'image_url' => 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=500',
            ],
            [
                'name' => 'Americano / Long Black',
                'price' => 18000,
                'description' => 'Double shot espresso arabica dengan air mineral dingin/hangat yang menyegarkan.',
                'image_url' => 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500',
            ],
            [
                'name' => 'Caffe Latte',
                'price' => 24000,
                'description' => 'Paduan seimbang single shot espresso dengan steamed milk yang halus dan lembut.',
                'image_url' => 'https://images.unsplash.com/photo-1561882468-9110e03e0f78?w=500',
            ],
            [
                'name' => 'Cappuccino',
                'price' => 24000,
                'description' => 'Espresso dengan lapisan foam susu tebal dan taburan bubuk dark chocolate.',
                'image_url' => 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500',
            ],
            [
                'name' => 'Caramel Macchiato',
                'price' => 26000,
                'description' => 'Espresso harum berlapis susu vanila dengan drizzle saus karamel lezat.',
                'image_url' => 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=500',
            ],
            [
                'name' => 'Mocha Latte',
                'price' => 25000,
                'description' => 'Perpaduan sempurna antara rasa kopi pahit dan manisnya cokelat premium.',
                'image_url' => 'https://images.unsplash.com/photo-1530373239216-42518e6b4063?w=500',
            ],
            [
                'name' => 'Vanilla Cold Brew',
                'price' => 25000,
                'description' => 'Kopi seduh dingin selama 12 jam dengan aroma manis sirup vanila.',
                'image_url' => 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500',
            ],
            [
                'name' => 'Espresso Single / Double',
                'price' => 15000,
                'description' => 'Ekstraksi murni biji kopi arabica dengan crema tebal keemasan.',
                'image_url' => 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=500',
            ],
        ];

        foreach ($coffeeMenus as $m) {
            DB::table('menus')->insert([
                'tenant_id' => $tenantId,
                'category_id' => $catCoffeeId,
                'name' => $m['name'],
                'price' => $m['price'],
                'description' => $m['description'],
                'image_url' => $m['image_url'],
                'is_available' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 4. Masukkan Menu NON-KOPI Say Coffee
        $nonCoffeeMenus = [
            [
                'name' => 'Matcha Latte Signature',
                'price' => 24000,
                'description' => 'Bubuk matcha Uji Jepang autentik dipadukan dengan fresh milk yang gurih.',
                'image_url' => 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500',
            ],
            [
                'name' => 'Chocolate Supreme',
                'price' => 22000,
                'description' => 'Cokelat Belgia pekat nan creamy, nikmat disajikan dingin maupun hangat.',
                'image_url' => 'https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?w=500',
            ],
            [
                'name' => 'Red Velvet Latte',
                'price' => 23000,
                'description' => 'Minuman manis gurih beraroma kue red velvet dengan hint buttermilk lembut.',
                'image_url' => 'https://images.unsplash.com/photo-1615478503562-ec2d8aa0e24e?w=500',
            ],
            [
                'name' => 'Taro Milk Tea',
                'price' => 22000,
                'description' => 'Rasa ubi taro manis harum khas Taiwan dipadukan dengan susu segar.',
                'image_url' => 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=500',
            ],
            [
                'name' => 'Thai Tea Original',
                'price' => 16000,
                'description' => 'Teh hitam rempah khas Thailand dengan susu kental manis gurih.',
                'image_url' => 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=500',
            ],
            [
                'name' => 'Fresh Lemon Tea',
                'price' => 15000,
                'description' => 'Seduhan teh melati dengan perasan lemon asli dan daun mint segar.',
                'image_url' => 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
            ],
            [
                'name' => 'Es Lychee Tea',
                'price' => 18000,
                'description' => 'Teh wangi dengan sirup leci dan buah leci asli yang manis menyegarkan.',
                'image_url' => 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
            ],
            [
                'name' => 'Es Teh Manis Melati',
                'price' => 8000,
                'description' => 'Teh melati racikan tradisional segar dengan es batu dingin.',
                'image_url' => 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500',
            ],
        ];

        foreach ($nonCoffeeMenus as $m) {
            DB::table('menus')->insert([
                'tenant_id' => $tenantId,
                'category_id' => $catNonCoffeeId,
                'name' => $m['name'],
                'price' => $m['price'],
                'description' => $m['description'],
                'image_url' => $m['image_url'],
                'is_available' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 5. Masukkan Topping Minuman Khusus Say Coffee
        $toppings = [
            ['name' => 'Extra Shot Espresso', 'price' => 5000],
            ['name' => 'Ganti Susu Oatmilk', 'price' => 6000],
            ['name' => 'Brown Sugar Boba', 'price' => 4000],
            ['name' => 'Coffee Jelly', 'price' => 4000],
            ['name' => 'Grass Jelly (Cincau)', 'price' => 3000],
            ['name' => 'Whipped Cream', 'price' => 5000],
            ['name' => 'Caramel Drizzle', 'price' => 3000],
            ['name' => 'Hazelnut Syrup', 'price' => 4000],
        ];

        $allMenuIds = DB::table('menus')->where('tenant_id', $tenantId)->pluck('id');

        foreach ($toppings as $t) {
            $toppingId = DB::table('toppings')->insertGetId([
                'tenant_id' => $tenantId,
                'name' => $t['name'],
                'price' => $t['price'],
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Hubungkan topping ke semua menu minuman
            foreach ($allMenuIds as $menuId) {
                DB::table('menu_toppings')->insert([
                    'menu_id' => $menuId,
                    'topping_id' => $toppingId,
                    'min' => 0,
                    'max' => 3,
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
        }
    }

    public function down(): void
    {
        //
    }
};
