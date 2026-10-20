<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            $table->foreignId('stock_item_id')->nullable()->after('category')->constrained('stock_items')->nullOnDelete();
            $table->decimal('quantity', 10, 2)->nullable()->after('description');
            $table->string('unit', 50)->nullable()->after('quantity');
        });
    }

    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            $table->dropForeign(['stock_item_id']);
            $table->dropColumn(['stock_item_id', 'quantity', 'unit']);
        });
    }
};
