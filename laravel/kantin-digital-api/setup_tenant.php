<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Tenant;
use Illuminate\Support\Facades\DB;

echo "=== Setup Tenant SAYUTIKOPI ===\n";

// 1. Buat tenant SAYUTIKOPI
$tenant = Tenant::whereIn('subdomain', ['sayutikopi', 'saycoffee'])->first();
if (!$tenant) {
    $tenant = Tenant::create([
        'subdomain'     => 'saycoffee',
        'name'          => 'SAYUTIKOPI',
        'logo_url'      => url('uploads/logos/logo_1_sayutikopi.png'),
        'primary_color' => '#C25E1E',
        'address'       => 'Jl. Kopi Nusantara No. 1',
        'phone'         => '0877-7126-2100',
        'whatsapp'      => '6287771262100',
        'plan'          => 'pro',
        'is_active'     => true,
    ]);
}
echo "Tenant dibuat: {$tenant->name} (ID: {$tenant->id}, subdomain: {$tenant->subdomain})\n";

$tenantId = $tenant->id;

// 2. Update semua data existing ke tenant ini
$tables = ['categories', 'menus', 'tables', 'toppings', 'orders', 'users'];

foreach ($tables as $table) {
    if (DB::getSchemaBuilder()->hasTable($table) && DB::getSchemaBuilder()->hasColumn($table, 'tenant_id')) {
        $count = DB::table($table)->whereNull('tenant_id')->update(['tenant_id' => $tenantId]);
        echo "  ✓ Tabel '$table': $count baris diupdate ke tenant_id=$tenantId\n";
    }
}

// 3. Update qris_settings juga
if (DB::getSchemaBuilder()->hasTable('qris_settings') && DB::getSchemaBuilder()->hasColumn('qris_settings', 'tenant_id')) {
    $count = DB::table('qris_settings')->whereNull('tenant_id')->update(['tenant_id' => $tenantId]);
    echo "  ✓ Tabel 'qris_settings': $count baris diupdate ke tenant_id=$tenantId\n";
}

echo "\n=== Selesai! Data SAY COFFEE berhasil dipindahkan ke tenant_id={$tenantId} ===\n";
echo "\nSubdomain lokal untuk testing:\n";
echo "  http://saycoffee.kantindigital.test/api/tenant/info\n";
echo "  http://saycoffee.kantindigital.test/api/menus\n";
