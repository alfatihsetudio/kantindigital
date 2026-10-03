<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('tenants') && ! Schema::hasColumn('tenants', 'menu_code_prefix')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('menu_code_prefix', 20)->nullable()->default('SAY')->after('name');
            });
        }

        if (Schema::hasTable('menus') && ! Schema::hasColumn('menus', 'code')) {
            Schema::table('menus', function (Blueprint $table) {
                $table->string('code', 50)->nullable()->after('category_id');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('tenants') && Schema::hasColumn('tenants', 'menu_code_prefix')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('menu_code_prefix');
            });
        }

        if (Schema::hasTable('menus') && Schema::hasColumn('menus', 'code')) {
            Schema::table('menus', function (Blueprint $table) {
                $table->dropColumn('code');
            });
        }
    }
};
