<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('order_type')->default('dine_in')->after('table_id');
            $table->text('delivery_address')->nullable()->after('order_type');
        });

        DB::table('orders')
            ->whereNull('table_id')
            ->update(['order_type' => 'pickup']);
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['order_type', 'delivery_address']);
        });
    }
};
