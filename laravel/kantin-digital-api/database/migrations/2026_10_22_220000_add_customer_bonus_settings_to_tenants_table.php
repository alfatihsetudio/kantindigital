<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->boolean('is_customer_bonus_active')->default(true)->after('order_notification_sound');
            $table->unsignedInteger('customer_bonus_percent')->default(0)->after('is_customer_bonus_active');
            $table->unsignedInteger('customer_bonus_min_spend')->default(0)->after('customer_bonus_percent');
        });
    }

    public function down(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn([
                'is_customer_bonus_active',
                'customer_bonus_percent',
                'customer_bonus_min_spend',
            ]);
        });
    }
};
