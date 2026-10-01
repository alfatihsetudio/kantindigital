<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        Category::insert($this->templates());
    }

    public function templates(): array
    {
        return [
            ['name' => 'Nasi & Rice Bowl'],
            ['name' => 'Mie & Pasta'],
            ['name' => 'Ayam & Daging'],
            ['name' => 'Seafood'],
            ['name' => 'Snack & Gorengan'],
            ['name' => 'Minuman Dingin'],
            ['name' => 'Minuman Panas'],
            ['name' => 'Dessert'],
        ];
    }
}
