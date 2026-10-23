<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('customer_bonuses', function (Blueprint $table) {
            $table->unsignedInteger('bonus_percent')->default(5)->after('customer_name');
            $table->boolean('is_active')->default(true)->after('bonus_percent');
            $table->string('notes', 255)->nullable()->after('is_active');
        });
    }

    public function down(): void
    {
        Schema::table('customer_bonuses', function (Blueprint $table) {
            $table->dropColumn(['bonus_percent', 'is_active', 'notes']);
        });
    }
};
