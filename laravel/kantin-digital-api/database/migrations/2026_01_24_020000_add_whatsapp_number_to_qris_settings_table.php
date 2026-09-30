<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('qris_settings', function (Blueprint $table) {
            $table->string('whatsapp_number')->nullable()->default('087771262100')->after('merchant_city');
        });
    }

    public function down(): void
    {
        Schema::table('qris_settings', function (Blueprint $table) {
            $table->dropColumn('whatsapp_number');
        });
    }
};
