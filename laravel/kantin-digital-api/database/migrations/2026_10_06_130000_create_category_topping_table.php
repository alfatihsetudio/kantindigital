<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('category_topping', function (Blueprint $table) {
            $table->id();
            $table->foreignId('category_id')->constrained()->cascadeOnDelete();
            $table->foreignId('topping_id')->constrained()->cascadeOnDelete();
            $table->timestamps();

            $table->unique(['category_id', 'topping_id']);
        });

        if (Schema::hasTable('menu_toppings')) {
            $now = now();
            $rows = DB::table('menu_toppings')
                ->join('menus', 'menus.id', '=', 'menu_toppings.menu_id')
                ->select('menus.category_id', 'menu_toppings.topping_id')
                ->distinct()
                ->get()
                ->map(fn ($row) => [
                    'category_id' => $row->category_id,
                    'topping_id' => $row->topping_id,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])
                ->all();

            if ($rows !== []) {
                DB::table('category_topping')->insertOrIgnore($rows);
            }
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('category_topping');
    }
};
