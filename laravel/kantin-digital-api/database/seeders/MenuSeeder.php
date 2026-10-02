<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Menu;

use App\Models\Tenant;

class MenuSeeder extends Seeder
{
    public function run(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->first();
        $tenantId = $tenant?->id;

        foreach ($this->templates() as $tpl) {
            $tpl['tenant_id'] = $tenantId;
            Menu::firstOrCreate(
                ['name' => $tpl['name'], 'tenant_id' => $tenantId],
                $tpl
            );
        }
    }

    public function templates(): array
    {
        return [
            // Nasi & Rice Bowl (category_id: 1)
            [
                'category_id' => 1,
                'name' => 'Nasi Goreng Spesial',
                'description' => 'Nasi goreng dengan telur, ayam, dan sayuran segar',
                'price' => 25000,
                'image_url' => 'https://images.unsplash.com/photo-1512058564366-18510be2db19?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 1,
                'name' => 'Nasi Goreng Seafood',
                'description' => 'Nasi goreng dengan udang, cumi, dan kerang',
                'price' => 35000,
                'image_url' => 'https://images.unsplash.com/photo-1603133872871-f5f3ed88f606?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 1,
                'name' => 'Nasi Ayam Geprek',
                'description' => 'Ayam geprek crispy dengan sambal pedas pilihan',
                'price' => 22000,
                'image_url' => 'https://images.unsplash.com/photo-1569058242567-93de6f36f8eb?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 1,
                'name' => 'Rice Bowl Beef Teriyaki',
                'description' => 'Rice bowl dengan daging sapi teriyaki dan sayuran',
                'price' => 32000,
                'image_url' => 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 1,
                'name' => 'Rice Bowl Chicken Katsu',
                'description' => 'Rice bowl dengan ayam katsu dan saus spesial',
                'price' => 28000,
                'image_url' => 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 1,
                'name' => 'Nasi Campur Bali',
                'description' => 'Nasi dengan ayam sisit, sate lilit, dan lawar',
                'price' => 35000,
                'image_url' => 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400',
                'is_available' => true,
            ],

            // Mie & Pasta (category_id: 2)
            [
                'category_id' => 2,
                'name' => 'Mie Ayam Bakso',
                'description' => 'Mie ayam dengan bakso sapi dan pangsit goreng',
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 2,
                'name' => 'Mie Goreng Jawa',
                'description' => 'Mie goreng dengan bumbu khas Jawa dan telur',
                'price' => 20000,
                'image_url' => 'https://images.unsplash.com/photo-1585032226651-759b368d7246?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 2,
                'name' => 'Spaghetti Carbonara',
                'description' => 'Pasta dengan saus krim, bacon, dan parmesan',
                'price' => 38000,
                'image_url' => 'https://images.unsplash.com/photo-1612874742237-6526221588e3?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 2,
                'name' => 'Spaghetti Bolognese',
                'description' => 'Pasta dengan saus daging sapi dan tomat',
                'price' => 35000,
                'image_url' => 'https://images.unsplash.com/photo-1598866594230-a7c12756260f?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 2,
                'name' => 'Indomie Goreng Spesial',
                'description' => 'Indomie goreng dengan telur, sosis, dan sayuran',
                'price' => 15000,
                'image_url' => 'https://images.unsplash.com/photo-1626804475297-41608ea09aeb?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 2,
                'name' => 'Kwetiau Goreng Seafood',
                'description' => 'Kwetiau dengan udang, cumi, dan sayuran',
                'price' => 28000,
                'image_url' => 'https://images.unsplash.com/photo-1617093727343-374698b1b08d?w=400',
                'is_available' => true,
            ],

            // Ayam & Daging (category_id: 3)
            [
                'category_id' => 3,
                'name' => 'Ayam Bakar Madu',
                'description' => 'Ayam bakar dengan bumbu madu dan rempah',
                'price' => 28000,
                'image_url' => 'https://images.unsplash.com/photo-1598103442097-8b74394b95c6?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 3,
                'name' => 'Ayam Penyet Sambal Ijo',
                'description' => 'Ayam goreng penyet dengan sambal hijau pedas',
                'price' => 25000,
                'image_url' => 'https://images.unsplash.com/photo-1632778149955-e80f8ceca2e8?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 3,
                'name' => 'Rendang Sapi',
                'description' => 'Daging sapi rendang dengan bumbu Padang asli',
                'price' => 40000,
                'image_url' => 'https://images.unsplash.com/photo-1545247181-516773cae754?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 3,
                'name' => 'Sate Ayam',
                'description' => '10 tusuk sate ayam dengan bumbu kacang',
                'price' => 25000,
                'image_url' => 'https://images.unsplash.com/photo-1529563021893-cc83c992d75d?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 3,
                'name' => 'Beef Steak',
                'description' => 'Steak daging sapi dengan saus blackpepper',
                'price' => 55000,
                'image_url' => 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 3,
                'name' => 'Chicken Wings BBQ',
                'description' => '6 pcs sayap ayam dengan saus BBQ',
                'price' => 30000,
                'image_url' => 'https://images.unsplash.com/photo-1527477396000-e27163b481c2?w=400',
                'is_available' => true,
            ],

            // Seafood (category_id: 4)
            [
                'category_id' => 4,
                'name' => 'Udang Saus Padang',
                'description' => 'Udang goreng tepung dengan saus Padang pedas',
                'price' => 45000,
                'image_url' => 'https://images.unsplash.com/photo-1565680018434-b513d5e5fd47?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 4,
                'name' => 'Cumi Goreng Tepung',
                'description' => 'Cumi goreng crispy dengan mayonnaise',
                'price' => 35000,
                'image_url' => 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 4,
                'name' => 'Ikan Bakar Rica-Rica',
                'description' => 'Ikan nila bakar dengan bumbu rica-rica',
                'price' => 40000,
                'image_url' => 'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 4,
                'name' => 'Kepiting Saus Tiram',
                'description' => 'Kepiting dengan saus tiram dan bawang putih',
                'price' => 75000,
                'image_url' => 'https://images.unsplash.com/photo-1559737558-2f5a35f4523b?w=400',
                'is_available' => true,
            ],

            // Snack & Gorengan (category_id: 5)
            [
                'category_id' => 5,
                'name' => 'French Fries',
                'description' => 'Kentang goreng crispy dengan saus',
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 5,
                'name' => 'Tahu Crispy',
                'description' => 'Tahu goreng crispy dengan saus kecap',
                'price' => 12000,
                'image_url' => 'https://images.unsplash.com/photo-1546069901-d5bfd2cbfb1f?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 5,
                'name' => 'Pisang Goreng Keju',
                'description' => 'Pisang goreng dengan topping keju dan susu',
                'price' => 15000,
                'image_url' => 'https://images.unsplash.com/photo-1528751014936-863e6e7a319c?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 5,
                'name' => 'Onion Rings',
                'description' => 'Bawang bombay goreng crispy',
                'price' => 15000,
                'image_url' => 'https://images.unsplash.com/photo-1639024471283-03518883512d?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 5,
                'name' => 'Nachos & Salsa',
                'description' => 'Tortilla chips dengan saus salsa dan keju',
                'price' => 22000,
                'image_url' => 'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 5,
                'name' => 'Risoles Mayo',
                'description' => 'Risoles isi sayuran dengan mayonnaise',
                'price' => 10000,
                'image_url' => 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=400',
                'is_available' => true,
            ],

            // Minuman Dingin (category_id: 6)
            [
                'category_id' => 6,
                'name' => 'Es Teh Manis',
                'description' => 'Teh manis dengan es batu segar',
                'price' => 8000,
                'image_url' => 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 6,
                'name' => 'Es Jeruk',
                'description' => 'Jus jeruk segar dengan es',
                'price' => 10000,
                'image_url' => 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 6,
                'name' => 'Es Kopi Susu',
                'description' => 'Kopi espresso dengan susu dan gula aren',
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 6,
                'name' => 'Jus Alpukat',
                'description' => 'Jus alpukat segar dengan susu coklat',
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1623065422902-30a2d299bbe4?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 6,
                'name' => 'Jus Mangga',
                'description' => 'Jus mangga segar tanpa gula',
                'price' => 15000,
                'image_url' => 'https://images.unsplash.com/photo-1546173159-315724a31696?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 6,
                'name' => 'Milkshake Coklat',
                'description' => 'Milkshake coklat dengan whipped cream',
                'price' => 22000,
                'image_url' => 'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 6,
                'name' => 'Lemon Tea',
                'description' => 'Teh lemon segar dengan es dan mint',
                'price' => 12000,
                'image_url' => 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 6,
                'name' => 'Thai Tea',
                'description' => 'Teh Thailand dengan susu kental manis',
                'price' => 15000,
                'image_url' => 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=400',
                'is_available' => true,
            ],

            // Minuman Panas (category_id: 7)
            [
                'category_id' => 7,
                'name' => 'Kopi Hitam',
                'description' => 'Kopi arabica tubruk tanpa gula',
                'price' => 10000,
                'image_url' => 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 7,
                'name' => 'Cappuccino',
                'description' => 'Espresso dengan foam susu dan bubuk coklat',
                'price' => 20000,
                'image_url' => 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 7,
                'name' => 'Latte',
                'description' => 'Espresso dengan susu steamed',
                'price' => 22000,
                'image_url' => 'https://images.unsplash.com/photo-1561882468-9110e03e0f78?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 7,
                'name' => 'Hot Chocolate',
                'description' => 'Coklat panas dengan marshmallow',
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1517578239113-b03992dcdd25?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 7,
                'name' => 'Teh Tarik',
                'description' => 'Teh tarik ala Malaysia',
                'price' => 12000,
                'image_url' => 'https://images.unsplash.com/photo-1558857563-b371033873b8?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 7,
                'name' => 'Wedang Jahe',
                'description' => 'Jahe hangat dengan gula merah',
                'price' => 10000,
                'image_url' => 'https://images.unsplash.com/photo-1544787219-7f47ccb76574?w=400',
                'is_available' => true,
            ],

            // Dessert (category_id: 8)
            [
                'category_id' => 8,
                'name' => 'Es Krim Sundae',
                'description' => 'Es krim vanilla dengan saus coklat dan kacang',
                'price' => 18000,
                'image_url' => 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 8,
                'name' => 'Brownies',
                'description' => 'Brownies coklat dengan es krim vanilla',
                'price' => 22000,
                'image_url' => 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 8,
                'name' => 'Es Campur',
                'description' => 'Es campur dengan buah-buahan dan sirup',
                'price' => 15000,
                'image_url' => 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 8,
                'name' => 'Pancake',
                'description' => 'Pancake dengan madu dan buah segar',
                'price' => 25000,
                'image_url' => 'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 8,
                'name' => 'Pudding Coklat',
                'description' => 'Pudding coklat dengan saus vanilla',
                'price' => 12000,
                'image_url' => 'https://images.unsplash.com/photo-1488477181946-6428a0291777?w=400',
                'is_available' => true,
            ],
            [
                'category_id' => 8,
                'name' => 'Waffle',
                'description' => 'Waffle dengan ice cream dan topping buah',
                'price' => 28000,
                'image_url' => 'https://images.unsplash.com/photo-1562376552-0d160a2f238d?w=400',
                'is_available' => true,
            ],
        ];
    }
}
