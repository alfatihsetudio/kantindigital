<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            if (! Schema::hasColumn('tenants', 'promo_payment_methods')) {
                $table->json('promo_payment_methods')->nullable()->after('promo_menu_ids');
            }
        });
    }

    public function down(): void
    {
        if (Schema::hasColumn('tenants', 'promo_payment_methods')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('promo_payment_methods');
            });
        }
    }
};
