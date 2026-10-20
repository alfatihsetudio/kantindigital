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
        Schema::table('tenants', function (Blueprint $table) {
            if (! Schema::hasColumn('tenants', 'delivery_discount_tiers')) {
                $table->json('delivery_discount_tiers')->nullable()->after('voucher_promo_mode');
            }
        });

        Schema::table('orders', function (Blueprint $table) {
            if (! Schema::hasColumn('orders', 'delivery_discount_amount')) {
                $table->unsignedInteger('delivery_discount_amount')->default(0)->after('voucher_discount_amount');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('tenants', 'delivery_discount_tiers')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('delivery_discount_tiers');
            });
        }

        if (Schema::hasColumn('orders', 'delivery_discount_amount')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropColumn('delivery_discount_amount');
            });
        }
    }
};
