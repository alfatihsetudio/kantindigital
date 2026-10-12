<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('vouchers')) {
            Schema::create('vouchers', function (Blueprint $table) {
                $table->id();
                $table->unsignedBigInteger('tenant_id')->nullable()->index();
                $table->string('partner_name', 120)->default('Umum')->index();
                $table->string('code', 100)->index();
                $table->integer('amount')->default(0);
                $table->string('status', 20)->default('unused')->index(); // unused, used
                $table->unsignedBigInteger('order_id')->nullable()->index();
                $table->string('order_code', 40)->nullable();
                $table->string('used_by_name', 100)->nullable();
                $table->string('used_by_phone', 40)->nullable();
                $table->timestamp('used_at')->nullable();
                $table->boolean('is_reported')->default(false)->index();
                $table->timestamp('reported_at')->nullable();
                $table->string('notes', 255)->nullable();
                $table->timestamps();

                $table->unique(['tenant_id', 'code']);
            });
        }

        Schema::table('orders', function (Blueprint $table) {
            if (! Schema::hasColumn('orders', 'voucher_code')) {
                $table->string('voucher_code', 100)->nullable()->after('discount_amount');
            }
            if (! Schema::hasColumn('orders', 'voucher_discount_amount')) {
                $table->integer('voucher_discount_amount')->default(0)->after('voucher_code');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'voucher_discount_amount')) {
                $table->dropColumn('voucher_discount_amount');
            }
            if (Schema::hasColumn('orders', 'voucher_code')) {
                $table->dropColumn('voucher_code');
            }
        });

        Schema::dropIfExists('vouchers');
    }
};
