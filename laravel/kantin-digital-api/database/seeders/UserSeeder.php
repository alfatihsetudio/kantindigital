<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\Tenant;
use App\Models\User;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tenant = Tenant::firstOrCreate(
            ['subdomain' => 'saycoffee'],
            [
                'name' => 'SAY COFFEE',
                'primary_color' => '#6F4E37',
                'address' => 'Serang - Banten',
                'phone' => '08123456789',
                'whatsapp' => '6287771262100',
                'plan' => 'pro',
                'is_active' => true,
            ]
        );

        // Admin/Operator
        User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Owner Pemilik',
            'email' => 'admin@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
        ]);

        // Kasir/Pelayan
        User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Cashier Staff',
            'email' => 'cashier@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'cashier',
        ]);

        // Operasional
        User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Staff Operasional',
            'email' => 'operasional@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'operations',
        ]);
        
        // Pimpinan (Manager)
        User::create([
            'tenant_id' => $tenant->id,
            'name' => 'Manager',
            'email' => 'manager@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'manager',
        ]);
    }
}
