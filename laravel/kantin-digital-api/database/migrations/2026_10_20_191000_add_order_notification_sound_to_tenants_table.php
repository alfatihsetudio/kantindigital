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
        if (Schema::hasTable('tenants') && ! Schema::hasColumn('tenants', 'order_notification_sound')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->string('order_notification_sound', 50)->default('dingdong')->after('delivery_discount_tiers');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasTable('tenants') && Schema::hasColumn('tenants', 'order_notification_sound')) {
            Schema::table('tenants', function (Blueprint $table) {
                $table->dropColumn('order_notification_sound');
            });
        }
    }
};
