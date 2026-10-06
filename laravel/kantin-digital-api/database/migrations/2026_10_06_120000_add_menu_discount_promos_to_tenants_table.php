<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            if (! Schema::hasColumn('tenants', 'promo_discount_percent')) {
                $table->unsignedTinyInteger('promo_discount_percent')->default(0);
            }
            if (! Schema::hasColumn('tenants', 'promo_scope')) {
                $table->string('promo_scope', 20)->default('all');
            }
            if (! Schema::hasColumn('tenants', 'promo_menu_ids')) {
                $table->json('promo_menu_ids')->nullable();
            }
        });
    }

    public function down(): void
    {
        $columns = array_filter([
            Schema::hasColumn('tenants', 'promo_discount_percent') ? 'promo_discount_percent' : null,
            Schema::hasColumn('tenants', 'promo_scope') ? 'promo_scope' : null,
            Schema::hasColumn('tenants', 'promo_menu_ids') ? 'promo_menu_ids' : null,
        ]);

        if ($columns !== []) {
            Schema::table('tenants', function (Blueprint $table) use ($columns) {
                $table->dropColumn($columns);
            });
        }
    }
};
