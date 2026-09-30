<?php

namespace Database\Seeders;

use App\Models\Table;
use Illuminate\Database\Seeder;

class TableSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tables = [
            // Indoor - Area A
            ['code' => 'A1', 'name' => 'Meja A1 (Indoor, 2 orang)'],
            ['code' => 'A2', 'name' => 'Meja A2 (Indoor, 2 orang)'],
            ['code' => 'A3', 'name' => 'Meja A3 (Indoor, 4 orang)'],
            ['code' => 'A4', 'name' => 'Meja A4 (Indoor, 4 orang)'],
            ['code' => 'A5', 'name' => 'Meja A5 (Indoor, 6 orang)'],
            
            // Indoor - Area B
            ['code' => 'B1', 'name' => 'Meja B1 (Indoor, 2 orang)'],
            ['code' => 'B2', 'name' => 'Meja B2 (Indoor, 2 orang)'],
            ['code' => 'B3', 'name' => 'Meja B3 (Indoor, 4 orang)'],
            ['code' => 'B4', 'name' => 'Meja B4 (Indoor, 4 orang)'],
            ['code' => 'B5', 'name' => 'Meja B5 (Indoor, 6 orang)'],
            
            // Outdoor - Area C
            ['code' => 'C1', 'name' => 'Meja C1 (Outdoor, 2 orang)'],
            ['code' => 'C2', 'name' => 'Meja C2 (Outdoor, 2 orang)'],
            ['code' => 'C3', 'name' => 'Meja C3 (Outdoor, 4 orang)'],
            ['code' => 'C4', 'name' => 'Meja C4 (Outdoor, 4 orang)'],
            ['code' => 'C5', 'name' => 'Meja C5 (Outdoor, 6 orang)'],
            
            // VIP Room - Area V
            ['code' => 'V1', 'name' => 'VIP Room 1 (8 orang)'],
            ['code' => 'V2', 'name' => 'VIP Room 2 (10 orang)'],
            ['code' => 'V3', 'name' => 'VIP Room 3 (12 orang)'],
        ];

        foreach ($tables as $table) {
            Table::firstOrCreate(
                ['code' => $table['code']],
                ['name' => $table['name']]
            );
        }
    }
}
