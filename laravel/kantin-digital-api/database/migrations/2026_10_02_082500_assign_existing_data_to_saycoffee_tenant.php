<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use App\Models\Tenant;

return new class extends Migration
{
    public function up(): void
    {
        $tenant = Tenant::where('subdomain', 'saycoffee')->first();
        if (!$tenant) {
            $tenantId = DB::table('tenants')->insertGetId([
                'subdomain' => 'saycoffee',
                'name' => 'SAY COFFEE',
                'primary_color' => '#6F4E37',
                'address' => 'Serang - Banten',
                'phone' => '08123456789',
                'whatsapp' => '6287771262100',
                'plan' => 'pro',
                'is_active' => true,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        } else {
            $tenantId = $tenant->id;
        }

        // Hubungkan semua data yang belum punya tenant_id ke Say Coffee
        $tables = ['categories', 'menus', 'toppings', 'tables', 'qris_settings'];
        foreach ($tables as $table) {
            if (DB::getSchemaBuilder()->hasTable($table) && DB::getSchemaBuilder()->hasColumn($table, 'tenant_id')) {
                DB::table($table)
                    ->whereNull('tenant_id')
                    ->update(['tenant_id' => $tenantId]);
            }
        }
    }

    public function down(): void
    {
        //
    }
};
