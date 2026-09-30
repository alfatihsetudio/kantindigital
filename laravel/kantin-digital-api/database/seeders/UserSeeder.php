<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Admin/Operator
        User::create([
            'name' => 'Admin Staff',
            'email' => 'admin@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'admin',
        ]);

        // Kasir/Pelayan
        User::create([
            'name' => 'Cashier Staff',
            'email' => 'cashier@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'cashier',
        ]);
        
        // Pimpinan (Manager)
        User::create([
            'name' => 'Manager',
            'email' => 'manager@gmail.com',
            'password' => Hash::make('admin123'),
            'role' => 'manager',
        ]);
    }
}
