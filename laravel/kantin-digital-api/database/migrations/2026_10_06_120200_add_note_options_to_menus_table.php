<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('menus', 'note_options')) {
            Schema::table('menus', function (Blueprint $table) {
                $table->json('note_options')->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('menus', 'note_options')) {
            Schema::table('menus', function (Blueprint $table) {
                $table->dropColumn('note_options');
            });
        }
    }
};
