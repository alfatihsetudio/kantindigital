<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tenants') && ! Schema::hasColumn('tenants', 'voucher_promo_mode')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('voucher_promo_mode', 30)
                    ->default('both')
                    ->after('promo_payment_methods');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tenants') && Schema::hasColumn('tenants', 'voucher_promo_mode')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('voucher_promo_mode');
            });
        }
    }
};
