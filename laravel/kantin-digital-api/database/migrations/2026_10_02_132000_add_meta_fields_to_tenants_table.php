<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            if (!Schema::hasColumn('tenants', 'meta_title')) {
                $table->string('meta_title')->nullable()->after('address');
            }
            if (!Schema::hasColumn('tenants', 'meta_description')) {
                $table->text('meta_description')->nullable()->after('meta_title');
            }
            if (!Schema::hasColumn('tenants', 'meta_image')) {
                $table->string('meta_image')->nullable()->after('meta_description');
            }
        });
    }

    public function down(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            $table->dropColumn(['meta_title', 'meta_description', 'meta_image']);
        });
    }
};
