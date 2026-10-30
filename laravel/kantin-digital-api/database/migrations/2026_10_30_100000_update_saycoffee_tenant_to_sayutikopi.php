<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use App\Models\Tenant;

return new class extends Migration
{
    public function up(): void
    {
        $tenant = Tenant::whereIn('subdomain', ['saycoffee', 'sayutikopi'])->first();
        if ($tenant) {
            $tenant->update([
                'name' => 'SAYUTIKOPI',
                'logo_url' => url('uploads/logos/logo_1_sayutikopi.png'),
                'meta_title' => 'SAYUTIKOPI - Nikmati, Ceritakan, Ulangi.',
                'meta_description' => "☕ SAYUTIKOPI sudah bisa dipesan!\nNikmati, Ceritakan, Ulangi. Pesan langsung di sini",
            ]);

            DB::table('qris_settings')
                ->where('tenant_id', $tenant->id)
                ->update(['merchant_name' => 'SAYUTIKOPI']);
        }
    }

    public function down(): void
    {
        $tenant = Tenant::whereIn('subdomain', ['saycoffee', 'sayutikopi'])->first();
        if ($tenant) {
            $tenant->update([
                'name' => 'SAY COFFEE',
            ]);
        }
    }
};
