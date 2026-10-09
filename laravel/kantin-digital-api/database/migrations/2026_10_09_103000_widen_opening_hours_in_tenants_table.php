<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('tenants', 'opening_hours')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('opening_hours', 255)->nullable()->default('08:00 - 22:00')->change();
            });
        } else {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('opening_hours', 255)->nullable()->default('08:00 - 22:00');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('tenants', 'opening_hours')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('opening_hours', 100)->nullable()->default('08:00 - 22:00')->change();
            });
        }
    }
};
