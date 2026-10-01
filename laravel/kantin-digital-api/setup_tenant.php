<?php

require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Tenant;
use Illuminate\Support\Facades\DB;

echo "=== Setup Tenant SAY COFFEE ===\n";

// 1. Buat tenant SAY COFFEE
$tenant = Tenant::firstOrCreate(
    ['subdomain' => 'saycoffee'],
    [
        'name'          => 'SAY COFFEE',
        'logo_url'      => null,
        'primary_color' => '#6F4E37',
        'address'       => 'Jl. Kopi Nusantara No. 1',
        'phone'         => '08123456789',
        'whatsapp'      => '628123456789',
        'plan'          => 'pro',
        'is_active'     => true,
    ]
);
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
