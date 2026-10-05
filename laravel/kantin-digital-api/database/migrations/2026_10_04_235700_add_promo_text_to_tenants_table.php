<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('tenants', 'promo_badge_text')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('promo_badge_text', 60)->nullable();
            });
        }

        if (! Schema::hasColumn('tenants', 'promo_message')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('promo_message', 180)->nullable();
            });
        }
    }

    public function down(): void
    {
        $columns = array_filter([
            Schema::hasColumn('tenants', 'promo_badge_text') ? 'promo_badge_text' : null,
            Schema::hasColumn('tenants', 'promo_message') ? 'promo_message' : null,
        ]);

        if ($columns !== []) {
            Schema::table('tenants', function (Blueprint $table) use ($columns) {
                $table->dropColumn($columns);
            });
        }
    }
};
