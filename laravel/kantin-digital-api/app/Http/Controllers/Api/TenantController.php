<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use App\Rules\SafeImageRule;
use App\Support\StoreOpeningHours;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class TenantController extends Controller
{
    /**
     * Info tenant dari subdomain aktif (dipanggil Flutter saat startup)
     */
    public function info(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
        }

        if (! $tenant) {
            return response()->json([
                'status' => false,
                'message' => 'Tenant tidak ditemukan',
            ], 404);
        }

        $qrisSetting = $tenant
            ? \App\Models\QrisSetting::withoutGlobalScopes()->where('tenant_id', $tenant->id)->first()
            : null;
        if (! $qrisSetting) {
            $qrisSetting = \App\Models\QrisSetting::withoutGlobalScopes()->first();
        }
        $whatsappNumber = $qrisSetting?->whatsapp_number ?? data_get($tenant, 'whatsapp') ?? data_get($tenant, 'phone') ?? '087771262100';

        return response()->json([
            'status' => true,
            'data' => [
                'id' => $tenant->id,
                'subdomain' => $tenant->subdomain,
                'name' => $tenant->name,
                'logo_url' => $tenant->logo_url,
                'primary_color' => $tenant->primary_color,
                'address' => $tenant->address,
                'opening_hours' => $tenant->opening_hours ?? '08:00 - 22:00',
                'is_store_open' => (bool) $tenant->is_store_open,
                'phone' => $tenant->phone,
                'whatsapp' => $tenant->whatsapp,
                'whatsapp_number' => $whatsappNumber,
                'plan' => $tenant->plan,
                'is_active' => $tenant->is_active,
                'meta_title' => $tenant->meta_title,
                'meta_description' => $tenant->meta_description,
                'meta_image' => $tenant->meta_image,
                'menu_code_prefix' => $tenant->menu_code_prefix ?? 'SAY',
                'promo_badge_text' => $tenant->promo_badge_text ?? 'Promo Hari Ini',
                'promo_message' => $tenant->promo_message ?? 'Pesan Sekarang, Nikmati Kemudahannya!',
                'promo_discount_percent' => (int) ($tenant->promo_discount_percent ?? 0),
                'promo_scope' => $tenant->promo_scope ?? 'all',
                'promo_menu_ids' => $tenant->promo_menu_ids ?? [],
                'promo_payment_methods' => $tenant->promo_payment_methods ?: ['qris'],
                'voucher_promo_mode' => $tenant->voucher_promo_mode ?? 'both',
            ],
        ]);
    }

    /**
     * Update profil tenant (nama kantin, logo, warna, whatsapp, dsb.)
     */
    public function update(Request $request)
    {
        try {
            $tenant = app()->has('tenant') ? app('tenant') : null;
            if (! $tenant && $request->user() && $request->user()->tenant_id) {
                $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
            }

            if (! $tenant) {
                return response()->json([
                    'status' => false,
                    'message' => 'Tenant tidak ditemukan',
                ], 404);
            }

            if ($request->has('promo_menu_ids') && is_string($request->input('promo_menu_ids'))) {
                $menuIds = json_decode($request->input('promo_menu_ids'), true);
                $request->merge([
                    'promo_menu_ids' => is_array($menuIds)
                        ? $menuIds
                        : $request->input('promo_menu_ids'),
                ]);
            }

            if ($request->has('promo_payment_methods') && is_string($request->input('promo_payment_methods'))) {
                $paymentMethods = json_decode($request->input('promo_payment_methods'), true);
                $request->merge([
                    'promo_payment_methods' => is_array($paymentMethods)
                        ? $paymentMethods
                        : $request->input('promo_payment_methods'),
                ]);
            }

            $request->validate([
                'name' => 'required|string|max:255',
                'menu_code_prefix' => 'nullable|string|max:20',
                'primary_color' => 'nullable|string',
                'logo_url' => 'nullable|string',
                'logo' => ['nullable', new SafeImageRule(2048)],
                'logo_base64' => 'nullable|string',
                'address' => 'nullable|string',
                'opening_hours' => [
                    'nullable',
                    'string',
                    'max:255',
                    function ($attribute, $value, $fail) {
                        if (! StoreOpeningHours::isValid($value)) {
                            $fail('Format jam operasional tidak dikenali.');
                        }
                    },
                ],
                'phone' => 'nullable|string',
                'whatsapp' => 'nullable|string',
                'meta_title' => 'nullable|string|max:255',
                'meta_description' => 'nullable|string|max:1000',
                'meta_image' => ['nullable', new SafeImageRule(5120)],
                'meta_image_url' => 'nullable|string',
                'meta_image_base64' => 'nullable|string',
                'promo_badge_text' => 'nullable|string|max:60',
                'promo_message' => 'nullable|string|max:180',
                'promo_discount_percent' => 'nullable|integer|min:0|max:100',
                'promo_scope' => 'nullable|in:all,selected',
                'promo_menu_ids' => 'nullable|array',
                'promo_menu_ids.*' => [
                    'integer',
                    'distinct',
                    Rule::exists('menus', 'id')->where('tenant_id', $tenant->id),
                ],
                'promo_payment_methods' => 'nullable|array',
                'promo_payment_methods.*' => 'string|in:qris,cash',
                'voucher_promo_mode' => 'nullable|string|in:both,single,voucher_only,promo_only',
            ]);

            if ((int) $request->input('promo_discount_percent', 0) > 0
                && $request->input('promo_scope', 'all') === 'selected'
                && empty($request->input('promo_menu_ids'))) {
                throw \Illuminate\Validation\ValidationException::withMessages([
                    'promo_menu_ids' => ['Pilih minimal satu menu untuk promo varian tertentu.'],
                ]);
            }

            $data = $request->only([
                'name', 'menu_code_prefix', 'promo_badge_text', 'promo_message',
                'promo_discount_percent', 'promo_scope', 'promo_menu_ids', 'promo_payment_methods',
                'voucher_promo_mode',
                'logo_url', 'primary_color', 'address', 'opening_hours', 'phone', 'whatsapp',
                'meta_title', 'meta_description',
            ]);

            if ($request->hasFile('logo') && $request->file('logo')->isValid()) {
                $file = $request->file('logo');
                $realPath = $file->getRealPath();
                if ($realPath && file_exists($realPath)) {
                    $rawBytes = @file_get_contents($realPath);
                    if ($rawBytes) {
                        $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');
                        $logoUrl = $this->storeCompressedLogo($tenant, $rawBytes, $extension);
                        if ($logoUrl) {
                            $data['logo_url'] = $logoUrl;
                        }
                    }
                }
            } elseif ($request->filled('logo_base64')) {
                // Backward compatible untuk client lama yang masih mengirim Base64.
                $base64String = $request->input('logo_base64');
                $extension = 'jpg';
                if (preg_match('/^data:image\/(\w+);base64,/', $base64String, $matches)) {
                    $extension = strtolower($matches[1]);
                    $base64String = substr($base64String, strpos($base64String, ',') + 1);
                }

                $binaryData = base64_decode($base64String);
                if ($binaryData !== false) {
                    $logoUrl = $this->storeCompressedLogo($tenant, $binaryData, $extension);
                    if ($logoUrl) {
                        $data['logo_url'] = $logoUrl;
                    }
                }
            }

            // Handle upload gambar meta preview link (OpenGraph / WhatsApp share preview)
            if ($request->hasFile('meta_image') && $request->file('meta_image')->isValid()) {
                $file = $request->file('meta_image');
                $realPath = $file->getRealPath();
                if ($realPath && file_exists($realPath)) {
                    $rawBytes = @file_get_contents($realPath);
                    if ($rawBytes) {
                        $extension = strtolower($file->getClientOriginalExtension() ?: 'jpg');
                        $metaImageUrl = $this->storeCompressedMetaImage($tenant, $rawBytes, $extension);
                        if ($metaImageUrl) {
                            $data['meta_image'] = $metaImageUrl;
                        }
                    }
                }
            } elseif ($request->filled('meta_image_base64')) {
                $base64String = $request->input('meta_image_base64');
                $extension = 'jpg';
                if (preg_match('/^data:image\/(\w+);base64,/', $base64String, $matches)) {
                    $extension = strtolower($matches[1]);
                    $base64String = substr($base64String, strpos($base64String, ',') + 1);
                }

                $binaryData = base64_decode($base64String);
                if ($binaryData !== false) {
                    $metaImageUrl = $this->storeCompressedMetaImage($tenant, $binaryData, $extension);
                    if ($metaImageUrl) {
                        $data['meta_image'] = $metaImageUrl;
                    }
                }
            } elseif ($request->has('meta_image_url')) {
                // Jika kosong string (""), berarti reset ke default (logo tenant)
                $metaUrlVal = $request->input('meta_image_url');
                $data['meta_image'] = !empty($metaUrlVal) ? $metaUrlVal : null;
            }

            $this->ensureVoucherPromoModeColumnExists();

            // Filter hanya kolom yang benar-benar ada di tabel tenants server
            // Mencegah SQL Error 1054 jika server belum menjalankan artisan migrate
            $filteredData = [];
            foreach ($data as $col => $val) {
                if (\Illuminate\Support\Facades\Schema::hasColumn('tenants', $col)) {
                    $filteredData[$col] = $val;
                }
            }

            $tenant->update($filteredData);
            $tenant->refresh();

            return response()->json([
                'status' => true,
                'message' => 'Profil kantin berhasil diperbarui',
                'data' => $tenant,
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            throw $e;
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Tenant update error: ' . $e->getMessage(), [
                'exception' => $e,
            ]);
            return response()->json([
                'status' => false,
                'message' => 'Error: ' . $e->getMessage(),
            ], 500);
        }
    }

    public function updateStoreStatus(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant) {
            return response()->json([
                'status' => false,
                'message' => 'Tenant tidak ditemukan',
            ], 404);
        }

        $validated = $request->validate([
            'is_store_open' => 'required|boolean',
        ]);

        $tenant->update([
            'is_store_open' => $validated['is_store_open'],
            'store_opened_at' => $validated['is_store_open']
                ? now('UTC')->toIso8601String()
                : null,
        ]);

        return response()->json([
            'status' => true,
            'message' => $validated['is_store_open']
                ? 'Toko berhasil dibuka.'
                : 'Toko berhasil ditutup.',
            'data' => [
                'is_store_open' => (bool) $tenant->is_store_open,
            ],
        ]);
    }

    public function updateOpeningHours(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
        }

        if (! $tenant) {
            return response()->json([
                'status' => false,
                'message' => 'Tenant tidak ditemukan',
            ], 404);
        }

        $validated = $request->validate([
            'opening_hours' => [
                'required',
                'string',
                'max:255',
                function ($attribute, $value, $fail) {
                    if (! StoreOpeningHours::isValid($value)) {
                        $fail('Format jam operasional tidak dikenali.');
                    }
                },
            ],
        ]);

        $tenant->update([
            'opening_hours' => $validated['opening_hours'],
        ]);
        $tenant->refresh();

        return response()->json([
            'status' => true,
            'message' => 'Jadwal operasional dan hari libur berhasil disimpan.',
            'data' => [
                'opening_hours' => $tenant->opening_hours,
            ],
        ]);
    }

    public function updateVoucherPromoMode(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
        }

        if (! $tenant) {
            return response()->json([
                'status' => false,
                'message' => 'Tenant tidak ditemukan',
            ], 404);
        }

        $validated = $request->validate([
            'voucher_promo_mode' => 'required|string|in:both,single,voucher_only,promo_only',
        ]);

        $this->ensureVoucherPromoModeColumnExists();

        if (\Illuminate\Support\Facades\Schema::hasColumn('tenants', 'voucher_promo_mode')) {
            $tenant->update([
                'voucher_promo_mode' => $validated['voucher_promo_mode'],
            ]);
            $tenant->refresh();
        }

        return response()->json([
            'status' => true,
            'message' => 'Pengaturan kombinasi voucher & diskon umum berhasil disimpan.',
            'data' => [
                'voucher_promo_mode' => $tenant->voucher_promo_mode ?? $validated['voucher_promo_mode'],
            ],
        ]);
    }

    private function ensureVoucherPromoModeColumnExists(): void
    {
        try {
            if (\Illuminate\Support\Facades\Schema::hasTable('tenants')
                && ! \Illuminate\Support\Facades\Schema::hasColumn('tenants', 'voucher_promo_mode')) {
                \Illuminate\Support\Facades\Schema::table('tenants', function (\Illuminate\Database\Schema\Blueprint $table) {
                    $table->string('voucher_promo_mode', 30)->default('both');
                });
            }
        } catch (\Throwable $e) {
            // Abaikan jika gagal auto-alter
        }
    }

    private function storeCompressedLogo(Tenant $tenant, string $binaryData, string $extension): ?string
    {
        try {
            $extension = strtolower($extension);
            if ($extension === 'jpeg') {
                $extension = 'jpg';
            }

            $extension = in_array($extension, ['jpg', 'png'], true) ? $extension : 'jpg';
            $directory = public_path('uploads/logos');

            if (! is_dir($directory)) {
                @mkdir($directory, 0777, true);
                @chmod($directory, 0777);
            }

            $filename = 'logo_'.$tenant->id.'_'.time().'.'.$extension;
            $targetPath = $directory.DIRECTORY_SEPARATOR.$filename;

            if (! extension_loaded('gd') || ! function_exists('imagecreatefromstring')) {
                @file_put_contents($targetPath, $binaryData);
                @chmod($targetPath, 0666);

                return url('uploads/logos/'.$filename);
            }

            $src = @imagecreatefromstring($binaryData);
            if (! $src) {
                @file_put_contents($targetPath, $binaryData);
                @chmod($targetPath, 0666);

                return url('uploads/logos/'.$filename);
            }

            $width = imagesx($src);
            $height = imagesy($src);
            $maxDim = 400;

            if ($width > $maxDim || $height > $maxDim) {
                $ratio = min($maxDim / $width, $maxDim / $height);
                $newWidth = max(1, (int) round($width * $ratio));
                $newHeight = max(1, (int) round($height * $ratio));
            } else {
                $newWidth = $width;
                $newHeight = $height;
            }

            $dst = imagecreatetruecolor($newWidth, $newHeight);
            if ($extension === 'png') {
                imagealphablending($dst, false);
                imagesavealpha($dst, true);
            }

            imagecopyresampled($dst, $src, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);

            if ($extension === 'png') {
                @imagepng($dst, $targetPath, 8);
            } else {
                @imagejpeg($dst, $targetPath, 82);
            }

            imagedestroy($dst);
            imagedestroy($src);
            @chmod($targetPath, 0666);

            return url('uploads/logos/'.$filename);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Logo compression error: ' . $e->getMessage());
            return null;
        }
    }

    private function storeCompressedMetaImage(Tenant $tenant, string $binaryData, string $extension): ?string
    {
        try {
            $extension = strtolower($extension);
            if ($extension === 'jpeg') {
                $extension = 'jpg';
            }

            $extension = in_array($extension, ['jpg', 'png', 'webp'], true) ? $extension : 'jpg';
            $directory = public_path('uploads/meta');

            if (! is_dir($directory)) {
                @mkdir($directory, 0777, true);
                @chmod($directory, 0777);
            }

            $filename = 'meta_'.$tenant->id.'_'.time().'.'.$extension;
            $targetPath = $directory.DIRECTORY_SEPARATOR.$filename;

            if (! extension_loaded('gd') || ! function_exists('imagecreatefromstring')) {
                @file_put_contents($targetPath, $binaryData);
                @chmod($targetPath, 0666);

                return url('uploads/meta/'.$filename);
            }

            $src = @imagecreatefromstring($binaryData);
            if (! $src) {
                @file_put_contents($targetPath, $binaryData);
                @chmod($targetPath, 0666);

                return url('uploads/meta/'.$filename);
            }

            $width = imagesx($src);
            $height = imagesy($src);
            // Social media meta images are typically 1200x630 or max 1200 px
            $maxDim = 1200;

            if ($width > $maxDim || $height > $maxDim) {
                $ratio = min($maxDim / $width, $maxDim / $height);
                $newWidth = max(1, (int) round($width * $ratio));
                $newHeight = max(1, (int) round($height * $ratio));
            } else {
                $newWidth = $width;
                $newHeight = $height;
            }

            $dst = imagecreatetruecolor($newWidth, $newHeight);
            if ($extension === 'png') {
                imagealphablending($dst, false);
                imagesavealpha($dst, true);
                imagecopyresampled($dst, $src, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
                @imagepng($dst, $targetPath, 8);
            } else {
                $white = imagecolorallocate($dst, 255, 255, 255);
                imagefill($dst, 0, 0, $white);
                imagecopyresampled($dst, $src, 0, 0, 0, 0, $newWidth, $newHeight, $width, $height);
                @imagejpeg($dst, $targetPath, 84);
            }

            imagedestroy($dst);
            imagedestroy($src);
            @chmod($targetPath, 0666);

            return url('uploads/meta/'.$filename);
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::error('Meta image compression error: ' . $e->getMessage());
            return null;
        }
    }

    /**
     * Daftar toko aktif yang sudah memiliki menu untuk ditampilkan di halaman showcase calon pembeli
     */
    public function showcaseStores(Request $request)
    {
        $query = Tenant::query()
            ->where('is_active', true)
            ->whereHas('menus', function ($q) {
                $q->withoutGlobalScope(\App\Models\Scopes\TenantScope::class);
            })
            ->withCount([
                'menus' => fn ($q) => $q->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
                'categories' => fn ($q) => $q->withoutGlobalScope(\App\Models\Scopes\TenantScope::class),
            ])
            ->with([
                'menus' => fn ($q) => $q->withoutGlobalScope(\App\Models\Scopes\TenantScope::class)
                    ->where('is_available', true)
                    ->select('id', 'tenant_id', 'name', 'price', 'image_url')
                    ->take(3),
            ])
            ->orderBy('id', 'asc');

        if ($search = $request->query('q')) {
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                    ->orWhere('subdomain', 'like', "%{$search}%")
                    ->orWhere('address', 'like', "%{$search}%");
            });
        }

        $tenants = $query->get();

        $host = $request->getHost();
        $scheme = ($request->isSecure() || $request->header('x-forwarded-proto') === 'https' || ! app()->isLocal()) ? 'https' : 'http';

        $data = $tenants->map(function ($tenant) use ($host, $scheme) {
            if (str_contains($host, 'kantindigital.test')) {
                $storeUrl = "{$scheme}://{$tenant->subdomain}.kantindigital.test";
            } else {
                $baseDomain = env('APP_MAIN_DOMAIN', 'ekasir.my.id');
                $storeUrl = "https://{$tenant->subdomain}.{$baseDomain}";
            }

            return [
                'id' => $tenant->id,
                'name' => $tenant->name,
                'subdomain' => $tenant->subdomain,
                'store_url' => $storeUrl,
                'logo_url' => $tenant->logo_url,
                'primary_color' => $tenant->primary_color ?? '#16A34A',
                'address' => $tenant->address,
                'opening_hours' => $tenant->opening_hours ?? '08:00 - 22:00',
                'phone' => $tenant->phone,
                'whatsapp' => $tenant->whatsapp,
                'meta_description' => $tenant->meta_description,
                'menus_count' => $tenant->menus_count,
                'categories_count' => $tenant->categories_count,
                'created_at' => $tenant->created_at?->format('d M Y'),
                'sample_menus' => $tenant->menus->map(fn ($m) => [
                    'name' => $m->name,
                    'price' => $m->price,
                    'image_url' => $m->image_url,
                ]),
            ];
        });

        return response()->json([
            'status' => true,
            'total' => $data->count(),
            'data' => $data,
        ]);
    }
}
