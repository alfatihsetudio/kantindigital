<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Menu;
use App\Models\Tenant;
use App\Models\Topping;
use Illuminate\Database\Seeder;

class SayCoffeeSeeder extends Seeder
{
    public function run(): void
    {
        // Cari tenant yang sudah ada (sayutikopi atau saycoffee)
        $tenant = Tenant::whereIn('subdomain', ['sayutikopi', 'saycoffee'])->first();
        if (!$tenant) {
            $tenant = Tenant::create([
                'subdomain' => 'saycoffee',
                'name' => 'SAYUTIKOPI',
                'logo_url' => url('uploads/logos/logo_1_sayutikopi.png'),
                'primary_color' => '#C25E1E',
                'address' => 'Jl. Kopi Nusantara No. 1',
                'phone' => '0877-7126-2100',
                'whatsapp' => '6287771262100',
                'plan' => 'pro',
                'is_active' => true,
                'menu_code_prefix' => 'SAY',
            ]);
        }

        if (empty($tenant->menu_code_prefix)) {
            $tenant->update(['menu_code_prefix' => 'SAY']);
        }

        $tenantId = $tenant->id;

        // Categories
        $catKopi = Category::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('name', 'Kopi')
            ->orderBy('id')
            ->firstOrCreate(
                ['name' => 'Kopi', 'tenant_id' => $tenantId],
                ['tenant_id' => $tenantId, 'is_active' => true]
            );

        $catNonKopi = Category::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('name', 'Non Kopi')
            ->orderBy('id')
            ->firstOrCreate(
                ['name' => 'Non Kopi', 'tenant_id' => $tenantId],
                ['tenant_id' => $tenantId, 'is_active' => true]
            );

        // Menus Kopi (01 - 06)
        $kopiMenus = [
            [
                'category_id' => $catKopi->id,
                'code' => '01',
                'name' => 'SAY AREN',
                'description' => 'Kopi susu gula aren racikan istimewa. "Manisnya pas, ceritanya bebas."',
                'price' => 15000,
                'image_url' => '/uploads/coffee.jpg',
                'is_available' => true,
            ],
            [
                'category_id' => $catKopi->id,
                'code' => '02',
                'name' => 'SAY BUTTER BLISS',
                'description' => 'Butterscotch harum, susu lembut, dan espresso. "Lembutkan rasa, ringankan suasana."',
                'price' => 15000,
                'image_url' => '/uploads/butter-bliss.jpg',
                'is_available' => true,
            ],
            [
                'category_id' => $catKopi->id,
                'code' => '03',
                'name' => 'SAY HAZEL HUG',
                'description' => 'Hazelnut premium, susu segar, dan espresso. "Nikmatnya seperti pelukan."',
                'price' => 15000,
                'image_url' => '/uploads/hazel-hug.jpg',
                'is_available' => true,
            ],
            [
                'category_id' => $catKopi->id,
                'code' => '04',
                'name' => 'SAY MILKY BREW',
                'description' => 'Espresso klasik dipadu susu gurih creamy. "Pelan-pelan, hari masih panjang."',
                'price' => 15000,
                'image_url' => '/uploads/milky-brew.jpg',
                'is_available' => true,
            ],
            [
                'category_id' => $catKopi->id,
                'code' => '05',
                'name' => 'SAY SWEET CREAM',
                'description' => 'Espresso bold dengan susu manis extra creamy. "Sedikit manis untuk hari yang lebih baik."',
                'price' => 18000,
                'image_url' => '/uploads/sweet-cream.jpg',
                'is_available' => true,
            ],
            [
                'category_id' => $catKopi->id,
                'code' => '06',
                'name' => 'SAY BLACK BREW',
                'description' => 'Americano dingin mantap & menyegarkan. "Sekali teguk, langsung jreeng.."',
                'price' => 12000,
                'image_url' => '/uploads/black-brew.jpg',
                'is_available' => true,
            ],
        ];

        // Menus Non Kopi (07 - 09)
        $nonKopiMenus = [
            [
                'category_id' => $catNonKopi->id,
                'code' => '07',
                'name' => 'SAY MATCHA MOOD',
                'description' => 'Matcha otentik yang creamy, wangi, dan lembut. "Balikan moodmu, lanjutkan harimu."',
                'price' => 15000,
                'image_url' => '/uploads/matcha.jpg',
                'is_available' => true,
            ],
            [
                'category_id' => $catNonKopi->id,
                'code' => '08',
                'name' => 'SAY CHOCO STORY',
                'description' => 'Cokelat kaya rasa berpadu susu creamy pekat. "Setiap cokelat punya cerita."',
                'price' => 18000,
                'image_url' => '/uploads/choco-story.jpg',
                'is_available' => true,
            ],
            [
                'category_id' => $catNonKopi->id,
                'code' => '09',
                'name' => 'SAY CHOCO HAZEL',
                'description' => 'Cokelat creamy berpadu aroma gurih hazelnut. "Manisnya bikin tenang, ceritanya terkenang."',
                'price' => 18000,
                'image_url' => '/uploads/choco-hazel.jpg',
                'is_available' => true,
            ],
        ];

        foreach (array_merge($kopiMenus, $nonKopiMenus) as $menuData) {
            $menuData['tenant_id'] = $tenantId;
            $menuData['note_options'] = ['Simple Sirup', 'Palm Sugar'];
            $existingMenu = Menu::withoutGlobalScopes()
                ->where('name', $menuData['name'])
                ->where('tenant_id', $tenantId)
                ->first();

            $existingImage = $existingMenu?->getRawOriginal('image_url');
            $existingImagePath = parse_url((string) $existingImage, PHP_URL_PATH);
            if (
                empty($existingImagePath)
                || in_array(basename($existingImagePath), ['coffee.jpg', 'matcha.jpg'], true)
            ) {
                $templatePath = public_path(ltrim($menuData['image_url'], '/'));
                if (! is_file($templatePath)) {
                    throw new \RuntimeException("Foto produk tidak ditemukan: {$templatePath}");
                }
            } else {
                $menuData['image_url'] = $existingImage;
            }

            Menu::withoutGlobalScopes()->updateOrCreate(
                ['name' => $menuData['name'], 'tenant_id' => $tenantId],
                $menuData
            );
        }

        // Toppings (Add-ons)
        $toppings = [
            ['name' => 'Extra Espresso', 'price' => 5000, 'tenant_id' => $tenantId],
            ['name' => 'Extra Syrup', 'price' => 3000, 'tenant_id' => $tenantId],
        ];

        foreach ($toppings as $top) {
            $topping = Topping::withoutGlobalScopes()->updateOrCreate(
                ['name' => $top['name'], 'tenant_id' => $tenantId],
                $top
            );
            $topping->categories()->syncWithoutDetaching([$catKopi->id, $catNonKopi->id]);
        }

        Category::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('name', 'Kopi')
            ->where('id', '!=', $catKopi->id)
            ->whereDoesntHave('menus')
            ->delete();
        Category::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('name', 'Non Kopi')
            ->where('id', '!=', $catNonKopi->id)
            ->whereDoesntHave('menus')
            ->delete();
    }
}
