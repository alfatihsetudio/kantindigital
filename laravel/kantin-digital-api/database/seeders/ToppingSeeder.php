<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Topping;

class ToppingSeeder extends Seeder
{
    public function run(): void
    {
        $toppings = [
            // Protein Toppings
            ['name' => 'Extra Telur Ceplok', 'price' => 5000],
            ['name' => 'Extra Telur Dadar', 'price' => 5000],
            ['name' => 'Extra Ayam Goreng', 'price' => 10000],
            ['name' => 'Extra Daging Sapi', 'price' => 15000],
            ['name' => 'Extra Udang (5 pcs)', 'price' => 12000],
            ['name' => 'Extra Cumi', 'price' => 10000],
            ['name' => 'Extra Bakso (3 pcs)', 'price' => 8000],
            ['name' => 'Extra Sosis (2 pcs)', 'price' => 6000],
            ['name' => 'Extra Nugget (3 pcs)', 'price' => 8000],
            ['name' => 'Extra Bacon', 'price' => 12000],

            // Cheese Toppings
            ['name' => 'Extra Keju Mozarella', 'price' => 8000],
            ['name' => 'Extra Keju Cheddar', 'price' => 6000],
            ['name' => 'Extra Keju Parmesan', 'price' => 10000],

            // Vegetable Toppings
            ['name' => 'Extra Sayuran', 'price' => 3000],
            ['name' => 'Extra Jamur', 'price' => 5000],
            ['name' => 'Extra Jagung', 'price' => 3000],
            
            // Sauce Toppings
            ['name' => 'Extra Sambal Matah', 'price' => 3000],
            ['name' => 'Extra Sambal Ijo', 'price' => 3000],
            ['name' => 'Extra Sambal Terasi', 'price' => 2000],
            ['name' => 'Extra Saus BBQ', 'price' => 3000],
            ['name' => 'Extra Saus Blackpepper', 'price' => 4000],
            ['name' => 'Extra Saus Mushroom', 'price' => 5000],
            ['name' => 'Extra Mayonnaise', 'price' => 2000],
            ['name' => 'Extra Saus Tartar', 'price' => 3000],

            // Rice/Noodle Add-ons
            ['name' => 'Extra Nasi', 'price' => 5000],
            ['name' => 'Extra Mie', 'price' => 5000],
            ['name' => 'Extra Kwetiau', 'price' => 5000],

            // Drink Add-ons
            ['name' => 'Extra Shot Espresso', 'price' => 5000],
            ['name' => 'Extra Susu', 'price' => 3000],
            ['name' => 'Extra Gula Aren', 'price' => 2000],
            ['name' => 'Extra Whipped Cream', 'price' => 5000],
            ['name' => 'Extra Boba', 'price' => 5000],
            ['name' => 'Extra Jelly', 'price' => 4000],
            ['name' => 'Upgrade Size L', 'price' => 5000],
            ['name' => 'Upgrade Size XL', 'price' => 8000],

            // Dessert Add-ons
            ['name' => 'Extra Ice Cream', 'price' => 8000],
            ['name' => 'Extra Madu', 'price' => 3000],
            ['name' => 'Extra Coklat Sauce', 'price' => 3000],
            ['name' => 'Extra Caramel Sauce', 'price' => 4000],
            ['name' => 'Extra Buah Segar', 'price' => 5000],
            ['name' => 'Extra Kacang', 'price' => 2000],

            // Spicy Level
            ['name' => 'Level Pedas 1 (Mild)', 'price' => 0],
            ['name' => 'Level Pedas 2 (Medium)', 'price' => 0],
            ['name' => 'Level Pedas 3 (Hot)', 'price' => 0],
            ['name' => 'Level Pedas 4 (Extra Hot)', 'price' => 2000],
            ['name' => 'Level Pedas 5 (DEVIL)', 'price' => 3000],
        ];

        $tenant = \App\Models\Tenant::where('subdomain', 'saycoffee')->first();
        $tenantId = $tenant?->id;

        // Create toppings and attach to relevant menus
        foreach ($toppings as $data) {
            $data['tenant_id'] = $tenantId;
            $topping = Topping::firstOrCreate(
                ['name' => $data['name'], 'tenant_id' => $tenantId],
                $data
            );
            $name = strtolower($data['name']);

            // Define category IDs based on topping type
            $categoryIds = [];

            if (str_contains($name, 'telur') || str_contains($name, 'ayam') || str_contains($name, 'daging') || str_contains($name, 'udang') || str_contains($name, 'cumi') || str_contains($name, 'bakso') || str_contains($name, 'sosis') || str_contains($name, 'nugget') || str_contains($name, 'bacon')) {
                // Protein: Nasi(1), Mie(2), Ayam(3), Seafood(4)
                $categoryIds = [1, 2, 3, 4];
            } elseif (str_contains($name, 'nasi') || str_contains($name, 'mie') || str_contains($name, 'kwetiau')) {
                // Carbs: Ayam(3), Seafood(4) (Addon)
                $categoryIds = [3, 4];
            } elseif (str_contains($name, 'sayur') || str_contains($name, 'jamur') || str_contains($name, 'jagung')) {
                // Veggies: Nasi(1), Mie(2)
                $categoryIds = [1, 2];
            } elseif (str_contains($name, 'keju') || str_contains($name, 'sauce') || str_contains($name, 'saus') || str_contains($name, 'sambal') || str_contains($name, 'mayonnaise')) {
                // Cheese/Sauce: Ayam(3), Seafood(4), Snack(5)
                $categoryIds = [3, 4, 5];
            } elseif (str_contains($name, 'espresso') || str_contains($name, 'susu') || str_contains($name, 'gula') || str_contains($name, 'whipped') || str_contains($name, 'boba') || str_contains($name, 'jelly') || str_contains($name, 'size')) {
                // Drinks: Cold(6), Hot(7)
                $categoryIds = [6, 7];
            } elseif (str_contains($name, 'ice cream') || str_contains($name, 'madu') || str_contains($name, 'buah')) {
                // Dessert: Dessert(8), Snack(5-pancake/waffle)
                $categoryIds = [5, 8];
            } elseif (str_contains($name, 'level pedas')) {
                // Spicy: Nasi(1), Mie(2), Ayam(3), Seafood(4)
                $categoryIds = [1, 2, 3, 4];
            }

            if (!empty($categoryIds)) {
                $topping->categories()->syncWithoutDetaching($categoryIds);

                // Find menus in these categories
                $menus = \App\Models\Menu::whereIn('category_id', $categoryIds)->get();
                if ($menus->isNotEmpty()) {
                    // Attach to all found menus
                    $topping->menus()->syncWithoutDetaching($menus->pluck('id'));
                }
            }
        }
    }
}
