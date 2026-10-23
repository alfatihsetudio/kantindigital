<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('customer_bonuses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('customer_phone', 30);
            $table->string('customer_name', 100)->nullable();
            $table->unsignedInteger('total_orders')->default(0);
            $table->unsignedBigInteger('total_spend')->default(0);
            $table->unsignedBigInteger('total_bonus_earned')->default(0);
            $table->unsignedBigInteger('total_bonus_claimed')->default(0);
            $table->unsignedBigInteger('bonus_balance')->default(0);
            $table->timestamp('last_order_at')->nullable();
            $table->timestamps();

            $table->unique(['tenant_id', 'customer_phone']);
            $table->index(['tenant_id', 'bonus_balance']);
        });

        Schema::create('customer_bonus_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('customer_bonus_id')->constrained('customer_bonuses')->cascadeOnDelete();
            $table->string('customer_phone', 30)->index();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->string('order_code', 50)->nullable();
            $table->enum('type', ['earn', 'claim', 'cancel'])->default('earn');
            $table->unsignedBigInteger('transaction_amount')->default(0);
            $table->unsignedInteger('bonus_percent')->default(0);
            $table->bigInteger('bonus_amount')->default(0);
            $table->unsignedBigInteger('balance_after')->default(0);
            $table->string('notes', 500)->nullable();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['tenant_id', 'customer_phone']);
            $table->index(['tenant_id', 'order_id']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->unsignedBigInteger('bonus_amount')->default(0)->after('delivery_discount_amount');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('bonus_amount');
        });

        Schema::dropIfExists('customer_bonus_logs');
        Schema::dropIfExists('customer_bonuses');
    }
};
