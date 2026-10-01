<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            // Drop existing foreign key constraint
            $table->dropForeign(['table_id']);

            // Make table_id nullable (pesanan online bisa tanpa meja)
            $table->unsignedBigInteger('table_id')->nullable()->change();

            // Re-add foreign key with nullOnDelete
            $table->foreign('table_id')
                  ->references('id')
                  ->on('tables')
                  ->nullOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['table_id']);
            $table->unsignedBigInteger('table_id')->nullable(false)->change();
            $table->foreign('table_id')
                  ->references('id')
                  ->on('tables')
                  ->cascadeOnDelete();
        });
    }
};
