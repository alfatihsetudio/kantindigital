<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Table;
use App\Models\Tenant;
use App\Models\User;
use Database\Seeders\CategorySeeder;
use Database\Seeders\MenuSeeder;
use App\Models\Menu;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class RegisterStoreController extends Controller
{
    /**
     * Daftar subdomain yang tidak boleh digunakan pengguna umum
     */
    protected array $reservedSubdomains = [
        'www', 'api', 'admin', 'superadmin', 'ekasir', 'kasirdigital', 'demo', 'staging',
        'mail', 'app', 'system', 'root', 'login', 'pos', 'dashboard', 'static', 'assets',
        'cdn', 'test', 'dev', 'support', 'help', 'manager', 'cashier', 'kitchen', 'owner',
        'billing', 'auth', 'portal'
    ];

    /**
     * Cek ketersediaan subdomain secara realtime
     */
    public function checkSubdomain(Request $request)
    {
        $rawSub = strtolower(trim((string) $request->query('subdomain', '')));
        $slug = Str::slug($rawSub);

        if (empty($slug)) {
            return response()->json([
                'status' => true,
                'available' => false,
                'subdomain' => '',
                'message' => 'Subdomain tidak boleh kosong.',
            ]);
        }

        if (strlen($slug) < 3) {
            return response()->json([
                'status' => true,
                'available' => false,
                'subdomain' => $slug,
                'message' => 'Subdomain minimal harus 3 karakter.',
            ]);
        }

        if (strlen($slug) > 50) {
            return response()->json([
                'status' => true,
                'available' => false,
                'subdomain' => $slug,
                'message' => 'Subdomain maksimal 50 karakter.',
            ]);
        }

        if (in_array($slug, $this->reservedSubdomains, true)) {
            return response()->json([
                'status' => true,
                'available' => false,
                'subdomain' => $slug,
                'message' => "Subdomain '$slug' merupakan kata kunci sistem dan tidak dapat digunakan.",
            ]);
        }

        $exists = Tenant::whereRaw('LOWER(subdomain) = ?', [$slug])->exists();

        return response()->json([
            'status' => true,
            'available' => ! $exists,
            'subdomain' => $slug,
            'message' => $exists
                ? "Subdomain '$slug' sudah digunakan oleh toko lain di website ini. Silakan pilih nama lain."
                : "Subdomain '$slug.ekasir.my.id' tersedia!",
        ]);
    }

    /**
     * Pendaftaran / Pembelian Website Toko Mandiri
     */
    public function registerStore(Request $request)
    {
        // Normalisasi subdomain & email
        if ($request->filled('subdomain')) {
            $request->merge(['subdomain' => Str::slug($request->input('subdomain'))]);
        }
        if ($request->filled('owner_email')) {
            $request->merge(['owner_email' => strtolower(trim($request->input('owner_email')))]);
        }

        $validated = $request->validate([
            'store_name' => ['required', 'string', 'max:255'],
            'subdomain' => [
                'required',
                'string',
                'max:63',
                Rule::notIn($this->reservedSubdomains),
                'unique:tenants,subdomain',
            ],
            'owner_name' => ['required', 'string', 'max:255'],
            'owner_email' => ['required', 'email', 'max:255', 'unique:users,email'],
            'whatsapp' => ['required', 'string', 'max:30'],
            'password' => ['required', 'string', 'min:6'],
            'plan' => ['required', Rule::in(['plan_30k', 'plan_70k', 'plan_100k', 'plan_1jt', 'starter', 'pro', 'basic'])],
            'payment_method' => ['nullable', 'string', 'max:50'],
            'address' => ['nullable', 'string', 'max:1000'],
            'category_type' => ['nullable', 'string', 'max:100'],
        ], [
            'subdomain.unique' => "Subdomain ':input' sudah terdaftar dan digunakan toko lain di website ini.",
            'subdomain.not_in' => "Subdomain ':input' merupakan kata kunci sistem dan tidak dapat digunakan.",
            'owner_email.unique' => 'Email pemilik sudah terdaftar. Silakan gunakan email lain atau hubungi admin.',
        ]);

        $subdomain = $validated['subdomain'];
        $cleanPrefix = strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $subdomain), 0, 3));
        if (strlen($cleanPrefix) < 2) {
            $cleanPrefix = 'KSR';
        }

        $selectedPlan = $validated['plan'];
        $expiresAt = ($selectedPlan === 'plan_1jt') ? now()->addYear() : now()->addMonth();

        $result = DB::transaction(function () use ($validated, $subdomain, $cleanPrefix, $selectedPlan, $expiresAt) {
            // 1. Buat Tenant baru
            $tenant = Tenant::create([
                'name' => $validated['store_name'],
                'subdomain' => $subdomain,
                'plan' => $selectedPlan,
                'expires_at' => $expiresAt,
                'is_active' => false,
                'whatsapp' => $validated['whatsapp'],
                'phone' => $validated['whatsapp'],
                'address' => $validated['address'] ?? null,
                'primary_color' => '#2563EB',
                'menu_code_prefix' => $cleanPrefix,
                'meta_title' => $validated['store_name'] . ' - Menu & Self-Order Digital',
                'meta_description' => 'Pesan makanan & minuman langsung dari meja di ' . $validated['store_name'],
            ]);

            // 2. Buat Akun Owner (Role: Admin)
            $owner = User::create([
                'tenant_id' => $tenant->id,
                'name' => $validated['owner_name'],
                'email' => $validated['owner_email'],
                'password' => $validated['password'], // di-hash otomatis oleh model cast
                'role' => 'admin',
                'must_change_password' => false,
            ]);

            // 3. Buat default kategori awal
            $defaultCategories = ['Makanan', 'Minuman', 'Snack & Cemilan'];
            $createdCategories = [];
            foreach ($defaultCategories as $catName) {
                $createdCategories[] = Category::create([
                    'tenant_id' => $tenant->id,
                    'name' => $catName,
                    'is_active' => true,
                ]);
            }

            // 4. Buat contoh meja awal (Meja 01 s.d Meja 05 + Takeaway)
            $defaultTables = [
                ['code' => '01', 'name' => 'Meja 01'],
                ['code' => '02', 'name' => 'Meja 02'],
                ['code' => '03', 'name' => 'Meja 03'],
                ['code' => '04', 'name' => 'Meja 04'],
                ['code' => '05', 'name' => 'Meja 05'],
                ['code' => 'TKW', 'name' => 'Bungkus / Takeaway'],
            ];
            foreach ($defaultTables as $table) {
                Table::create([
                    'tenant_id' => $tenant->id,
                    'code' => $table['code'],
                    'name' => $table['name'],
                ]);
            }

            // 5. Buat invoice code unik
            $invoiceCode = 'INV-' . strtoupper(Str::random(4)) . '-' . date('ymd');

            return [
                'tenant' => $tenant,
                'owner' => $owner,
                'invoice_code' => $invoiceCode,
            ];
        });

        $tenant = $result['tenant'];
        $owner = $result['owner'];
        $invoiceCode = $result['invoice_code'];

        $storeUrl = "https://{$tenant->subdomain}.ekasir.my.id";
        $loginUrl = "https://{$tenant->subdomain}.ekasir.my.id/#/admin/login";

        $planPrices = [
            'plan_30k' => 30000,
            'plan_70k' => 70000,
            'plan_100k' => 100000,
            'plan_1jt' => 1000000,
            'starter' => 99000,
            'basic' => 99000,
            'pro' => 199000,
        ];
        $amount = $planPrices[$selectedPlan] ?? 30000;
        
        // QRIS pembayaran aktivasi website platform menggunakan QRIS utama (SAYUTIKOPI)
        $saycoffeeTenant = Tenant::whereIn('subdomain', ['sayutikopi', 'saycoffee'])->first() ?? Tenant::find(1);
        $qrisSetting = $saycoffeeTenant
            ? \App\Models\QrisSetting::withoutGlobalScopes()->where('tenant_id', $saycoffeeTenant->id)->first()
            : null;

        if (!$qrisSetting) {
            $qrisSetting = \App\Models\QrisSetting::withoutGlobalScopes()->where('tenant_id', 1)->first()
                ?? \App\Models\QrisSetting::withoutGlobalScopes()->where('merchant_name', 'like', '%SAYUTIKOPI%')->first()
                ?? \App\Models\QrisSetting::withoutGlobalScopes()->where('merchant_name', 'like', '%Say Coffee%')->first()
                ?? \App\Models\QrisSetting::withoutGlobalScopes()->first();
        }

        $merchantName = $qrisSetting->merchant_name ?? env('QRIS_MERCHANT_NAME', 'SAYUTIKOPI');
        $merchantCity = $qrisSetting->merchant_city ?? env('QRIS_MERCHANT_CITY', 'Kab. Serang');
        $basePayload = (!empty($qrisSetting->base_payload))
            ? $qrisSetting->base_payload
            : env('QRIS_BASE_PAYLOAD', '00020101021126570011ID.DANA.WWW011893600915303557205402090355720540303UMI51440014ID.CO.QRIS.WWW0215ID10266058542500303UMI5204581253033605802ID5910Say Coffee6011Kab. Serang6105421176304AB0C');
        $whatsappNumber = $qrisSetting->whatsapp_number ?? env('QRIS_WHATSAPP_NUMBER', '087771262100');

        $qrisService = app(\App\Services\QrisDynamicService::class);
        $qrisPayload = $qrisService->generatePayload($basePayload, $amount);

        // Buat Order pencatatan pembayaran platform (SAYUTIKOPI) dengan status UNPAID
        $platformTenant = Tenant::whereIn('subdomain', ['sayutikopi', 'saycoffee'])->first();
        $platformTenantId = $platformTenant?->id ?? 1;

        \App\Models\Order::withoutGlobalScopes()->create([
            'tenant_id' => $platformTenantId,
            'code' => $invoiceCode,
            'customer_name' => $owner->name,
            'customer_phone' => $tenant->whatsapp,
            'status' => 'UNPAID',
            'payment_method' => 'qris',
            'total_amount' => $amount,
            'order_type' => 'pickup',
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Selamat! Website toko Anda telah dibuat. Silakan scan QRIS untuk mengaktifkannya secara otomatis.',
            'data' => [
                'tenant_id' => $tenant->id,
                'store_name' => $tenant->name,
                'subdomain' => $tenant->subdomain,
                'store_url' => $storeUrl,
                'login_url' => $loginUrl,
                'owner' => [
                    'name' => $owner->name,
                    'email' => $owner->email,
                ],
                'invoice' => [
                    'code' => $invoiceCode,
                    'plan' => $validated['plan'],
                    'amount' => $amount,
                    'payment_method' => $validated['payment_method'] ?? 'qris',
                    'status' => 'unpaid',
                ],
                'qris' => [
                    'merchant_name' => $merchantName,
                    'merchant_city' => $merchantCity,
                    'whatsapp_number' => $whatsappNumber,
                    'payload' => $qrisPayload,
                    'amount' => $amount,
                ],
            ],
        ], 201);
    }

    /**
     * Cek status pembayaran invoice aktivasi toko secara realtime
     */
    public function checkStatus(string $invoiceCode)
    {
        $order = \App\Models\Order::withoutGlobalScopes()->where('code', $invoiceCode)->first();
        if (!$order) {
            return response()->json([
                'status' => false,
                'message' => 'Invoice tagihan tidak ditemukan.',
            ], 404);
        }

        $isPaid = strtoupper((string) $order->status) === 'PAID';
        $tenant = Tenant::where('whatsapp', $order->customer_phone)
            ->orWhere('phone', $order->customer_phone)
            ->latest()
            ->first();

        if ($isPaid && $tenant && !$tenant->is_active) {
            $tenant->update(['is_active' => true]);
        }

        return response()->json([
            'status' => true,
            'data' => [
                'invoice_code' => $order->code,
                'status' => $order->status,
                'is_paid' => $isPaid,
                'amount' => $order->total_amount,
                'tenant' => $tenant ? [
                    'id' => $tenant->id,
                    'name' => $tenant->name,
                    'subdomain' => $tenant->subdomain,
                    'is_active' => (bool) $tenant->is_active,
                    'store_url' => "https://{$tenant->subdomain}.ekasir.my.id",
                    'login_url' => "https://{$tenant->subdomain}.ekasir.my.id/#/admin/login",
                ] : null,
            ],
        ]);
    }

    /**
     * Simulasi pelunasan invoice (untuk testing atau konfirmasi manual)
     */
    public function simulatePaid(string $invoiceCode)
    {
        $order = \App\Models\Order::withoutGlobalScopes()->where('code', $invoiceCode)->first();
        if (!$order) {
            return response()->json(['status' => false, 'message' => 'Invoice tagihan tidak ditemukan.'], 404);
        }

        $order->update(['status' => 'PAID']);
        $tenant = Tenant::where('whatsapp', $order->customer_phone)
            ->orWhere('phone', $order->customer_phone)
            ->latest()
            ->first();
        if ($tenant) {
            $tenant->update(['is_active' => true]);
        }

        return response()->json([
            'status' => true,
            'message' => "Invoice #{$order->code} berhasil diubah menjadi PAID dan toko aktif.",
            'data' => [
                'invoice_code' => $order->code,
                'status' => 'PAID',
                'is_paid' => true,
            ],
        ]);
    }
}
