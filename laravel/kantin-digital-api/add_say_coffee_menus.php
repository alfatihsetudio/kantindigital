<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Category;
use App\Models\Menu;
use App\Models\Topping;

echo "=== Memproses Kategori & Menu SAY COFFEE ===\n";

// 1. Buat / Ambil Kategori Kopi & Non Kopi
$kopiCategory = Category::firstOrCreate(['name' => 'Kopi']);
$nonKopiCategory = Category::firstOrCreate(['name' => 'Non Kopi']);

echo "Kategori Kopi ID: {$kopiCategory->id}\n";
echo "Kategori Non Kopi ID: {$nonKopiCategory->id}\n";

// Topping ID untuk Minuman: 28 s/d 41
// (Extra Shot Espresso, Extra Susu, Extra Gula Aren, Extra Whipped Cream, Extra Boba, Extra Jelly, Upgrade Size L, Upgrade Size XL, Extra Ice Cream, Extra Madu, Extra Coklat Sauce, Extra Caramel Sauce)
$drinkToppingIds = [28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39];
$validToppingIds = Topping::whereIn('id', $drinkToppingIds)->pluck('id')->toArray();

$menusData = [
    // KOPI
    [
        'category_id' => $kopiCategory->id,
        'name' => 'SAY AREN',
        'price' => 15000,
        'description' => 'Kopi susu gula aren ("Manisnya pas, ceritanya bebas.")',
        'image_url' => 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=500',
        'is_available' => 1,
    ],
    [
        'category_id' => $kopiCategory->id,
        'name' => 'SAY BUTTER BLISS',
        'price' => 15000,
        'description' => 'Butterscotch, susu, dan espresso ("Lembutkan rasa, ringankan suasana.")',
        'image_url' => 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=500',
        'is_available' => 1,
    ],
    [
        'category_id' => $kopiCategory->id,
        'name' => 'SAY HAZEL HUG',
        'price' => 15000,
        'description' => 'Hazelnut, susu, dan espresso ("Nikmatnya seperti pelukan.")',
        'image_url' => 'https://images.unsplash.com/photo-1541167760496-1628856ab772?w=500',
        'is_available' => 1,
    ],
    [
        'category_id' => $kopiCategory->id,
        'name' => 'SAY MILKY BREW',
        'price' => 15000,
        'description' => 'Espresso dan susu ("Pelan-pelan, hari masih panjang.")',
        'image_url' => 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=500',
        'is_available' => 1,
    ],
    [
        'category_id' => $kopiCategory->id,
        'name' => 'SAY SWEET CREAM',
        'price' => 18000,
        'description' => 'Espresso dan susu creamy ("Sedikit manis untuk hari yang lebih baik.")',
        'image_url' => 'https://images.unsplash.com/photo-1534778101976-62847782c213?w=500',
        'is_available' => 1,
    ],
    [
        'category_id' => $kopiCategory->id,
        'name' => 'SAY BLACK BREW',
        'price' => 12000,
        'description' => 'Americano dingin ("Sekali teguk, langsung jreeng..")',
        'image_url' => 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=500',
        'is_available' => 1,
    ],

    // NON KOPI
    [
        'category_id' => $nonKopiCategory->id,
        'name' => 'SAY MATCHA MOOD',
        'price' => 15000,
        'description' => 'Matcha creamy dan lembut ("Balikan moodmu, lanjutkan harimu.")',
        'image_url' => 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500',
        'is_available' => 1,
    ],
    [
        'category_id' => $nonKopiCategory->id,
        'name' => 'SAY CHOCO STORY',
        'price' => 18000,
        'description' => 'Cokelat creamy ("Setiap cokelat punya cerita.")',
        'image_url' => 'https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?w=500',
        'is_available' => 1,
    ],
    [
        'category_id' => $nonKopiCategory->id,
        'name' => 'SAY CHOCO HAZEL',
        'price' => 18000,
        'description' => 'Cokelat creamy dan hazelnut ("Manisnya bikin tenang, ceritanya terkenang.")',
        'image_url' => 'https://images.unsplash.com/photo-1511920170033-f8396924c348?w=500',
        'is_available' => 1,
    ],
];

foreach ($menusData as $data) {
    $menu = Menu::updateOrCreate(
        ['name' => $data['name']],
        $data
    );

    // Sync topping minuman
    if (!empty($validToppingIds)) {
        $menu->toppings()->syncWithoutDetaching($validToppingIds);
    }

    echo "Menu berhasil ditambahkan/diupdate: {$menu->name} (Rp " . number_format($menu->price, 0, ',', '.') . ")\n";
}

echo "=== Selesai! Semua menu Say Coffee telah masuk ke database ===\n";
