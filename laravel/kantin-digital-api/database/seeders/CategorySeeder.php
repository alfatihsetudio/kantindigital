<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Category;

use App\Models\Tenant;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->first();
        $tenantId = $tenant?->id;

        foreach ($this->templates() as $tpl) {
            Category::firstOrCreate(
                ['name' => $tpl['name'], 'tenant_id' => $tenantId],
                ['tenant_id' => $tenantId, 'is_active' => true]
            );
        }
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
