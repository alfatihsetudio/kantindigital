<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('order_item_toppings', 'quantity')) {
            Schema::table('order_item_toppings', function (Blueprint $table) {
                $table->unsignedInteger('quantity')->default(1);
            });
        }

        if (! Schema::hasColumn('order_items', 'discount_amount')) {
            Schema::table('order_items', function (Blueprint $table) {
                $table->unsignedInteger('discount_amount')->default(0);
            });
        }

        if (! Schema::hasColumn('orders', 'discount_amount')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->unsignedInteger('discount_amount')->default(0);
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('order_item_toppings', 'quantity')) {
            Schema::table('order_item_toppings', function (Blueprint $table) {
                $table->dropColumn('quantity');
            });
        }
        if (Schema::hasColumn('order_items', 'discount_amount')) {
            Schema::table('order_items', function (Blueprint $table) {
                $table->dropColumn('discount_amount');
            });
        }
        if (Schema::hasColumn('orders', 'discount_amount')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('discount_amount');
            });
        }
    }
};
