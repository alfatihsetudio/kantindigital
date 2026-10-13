<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stock_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete();
            $table->string('name');
            $table->string('unit')->default('gram'); // gram, ml, pcs, kg, botol, pack
            $table->string('category')->nullable()->default('Bahan Baku');
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['tenant_id', 'is_active']);
        });

        Schema::create('stock_checks', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained('tenants')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->enum('check_type', ['closing', 'opening']); // closing (tutup toko), opening (buka toko)
            $table->date('check_date');
            $table->string('status')->default('completed'); // completed, has_difference
            $table->unsignedInteger('total_items')->default(0);
            $table->unsignedInteger('matched_items')->default(0);
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'check_date']);
            $table->index(['tenant_id', 'check_type']);
        });

        Schema::create('stock_check_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('stock_check_id')->constrained('stock_checks')->cascadeOnDelete();
            $table->foreignId('stock_item_id')->nullable()->constrained('stock_items')->nullOnDelete();
            $table->string('item_name');
            $table->string('unit')->default('gram');
            $table->decimal('whole_quantity', 10, 2)->default(0); // misal: 2 botol utuh / 5 bungkus utuh
            $table->decimal('remainder_quantity', 10, 2)->default(0); // misal: sisa 450 gram
            $table->decimal('previous_whole_quantity', 10, 2)->nullable();
            $table->decimal('previous_remainder_quantity', 10, 2)->nullable();
            $table->decimal('difference_whole', 10, 2)->default(0);
            $table->decimal('difference_remainder', 10, 2)->default(0);
            $table->boolean('is_matched')->default(true);
            $table->string('notes')->nullable();
            $table->timestamps();

            $table->index('stock_check_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stock_check_items');
        Schema::dropIfExists('stock_checks');
        Schema::dropIfExists('stock_items');
    }
};
