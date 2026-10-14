<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cashier_shift_reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete();
            $table->foreignId('cashier_id')->constrained('users')->cascadeOnDelete();
            $table->dateTime('shift_opened_at')->nullable();
            $table->dateTime('shift_closed_at')->nullable();
            $table->unsignedInteger('total_orders')->default(0);
            $table->decimal('total_cash_expected', 14, 2)->default(0);
            $table->decimal('total_qris_expected', 14, 2)->default(0);
            $table->decimal('total_sales_expected', 14, 2)->default(0);
            $table->decimal('cash_received', 14, 2)->default(0);
            $table->decimal('cash_difference', 14, 2)->default(0);
            $table->string('status', 30)->default('PENDING'); // PENDING, APPROVED, REJECTED
            $table->text('cashier_notes')->nullable();
            $table->foreignId('approved_by')->nullable()->constrained('users')->nullOnDelete();
            $table->dateTime('approved_at')->nullable();
            $table->text('approval_notes')->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'status']);
            $table->index(['tenant_id', 'created_at']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->foreignId('cashier_shift_report_id')
                ->nullable()
                ->after('status')
                ->constrained('cashier_shift_reports')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['cashier_shift_report_id']);
            $table->dropColumn('cashier_shift_report_id');
        });

        Schema::dropIfExists('cashier_shift_reports');
    }
};
