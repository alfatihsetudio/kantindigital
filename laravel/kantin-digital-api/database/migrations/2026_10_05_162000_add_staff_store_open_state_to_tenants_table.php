<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('tenants', 'is_store_open')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->boolean('is_store_open')->default(false);
            });
        }

        if (! Schema::hasColumn('tenants', 'store_opened_at')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('store_opened_at', 40)->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('tenants', 'store_opened_at')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('store_opened_at');
            });
        }

        if (Schema::hasColumn('tenants', 'is_store_open')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('is_store_open');
            });
        }
    }
};
