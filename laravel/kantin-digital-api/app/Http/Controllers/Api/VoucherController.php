<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class VoucherController extends Controller
{
    /**
     * Public & Cashier endpoint: cek kode voucher di tabel vouchers
     */
    public function check(Request $request)
    {
        $request->validate([
            'code' => ['required', 'string', 'max:100'],
            'subtotal' => ['nullable', 'numeric', 'min:0'],
        ], [
            'code.required' => 'Kode voucher wajib diisi.',
        ]);

        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
        }
        $voucherPromoMode = data_get($tenant, 'voucher_promo_mode', 'both') ?: 'both';

        if ($voucherPromoMode === 'promo_only') {
            return response()->json([
                'status' => false,
                'message' => 'Penggunaan kode voucher sedang dinonaktifkan (hanya berlaku diskon promo umum).',
            ], 422);
        }

        $rawCode = strtoupper(trim((string) $request->input('code')));
        if ($rawCode === '') {
            return response()->json([
                'status' => false,
                'message' => 'Kode voucher wajib diisi.',
            ], 422);
        }

        $voucher = Voucher::whereRaw('UPPER(code) = ?', [$rawCode])->first();

        if (! $voucher) {
            return response()->json([
                'status' => false,
                'message' => 'Kode voucher tidak ditemukan atau tidak terdaftar.',
            ], 404);
        }

        if ($voucher->status === 'used') {
            return response()->json([
                'status' => false,
                'message' => 'Kode voucher ini sudah pernah digunakan.',
            ], 422);
        }

        $amount = max(0, (int) $voucher->amount);
        $subtotal = $request->filled('subtotal') ? max(0, (int) $request->input('subtotal')) : null;
        $discountAmount = $subtotal !== null ? min($subtotal, $amount) : $amount;

        return response()->json([
            'status' => true,
            'message' => 'Kode voucher valid!',
            'data' => [
                'id' => $voucher->id,
                'code' => $voucher->code,
                'partner_name' => $voucher->partner_name,
                'amount' => $amount,
                'discount_amount' => $discountAmount,
                'status' => $voucher->status,
                'voucher_promo_mode' => $voucherPromoMode,
            ],
        ]);
    }

    /**
     * Admin & Manager endpoint: daftar voucher & ringkasan laporan kerjasama
     */
    public function index(Request $request)
    {
        $query = Voucher::query();

        if ($request->filled('status') && in_array($request->status, ['unused', 'used'], true)) {
            $query->where('status', $request->status);
        }

        if ($request->filled('partner_name') && $request->partner_name !== 'ALL') {
            $query->where('partner_name', $request->partner_name);
        }

        if ($request->filled('is_reported')) {
            $isReported = filter_var($request->is_reported, FILTER_VALIDATE_BOOLEAN, FILTER_NULL_ON_FAILURE);
            if ($isReported !== null) {
                $query->where('is_reported', $isReported);
            }
        }

        if ($request->filled('search')) {
            $search = trim((string) $request->search);
            $query->where(function ($q) use ($search) {
                $q->where('code', 'like', "%{$search}%")
                    ->orWhere('partner_name', 'like', "%{$search}%")
                    ->orWhere('order_code', 'like', "%{$search}%")
                    ->orWhere('used_by_name', 'like', "%{$search}%")
                    ->orWhere('used_by_phone', 'like', "%{$search}%");
            });
        }

        $vouchers = $query
            ->orderByRaw("CASE WHEN status = 'used' THEN 0 ELSE 1 END")
            ->orderByDesc('used_at')
            ->orderByDesc('id')
            ->limit(500)
            ->get();

        // Statistik keseluruhan untuk tenant aktif
        $allQuery = Voucher::query();
        if ($request->filled('partner_name') && $request->partner_name !== 'ALL') {
            $allQuery->where('partner_name', $request->partner_name);
        }

        $totalVouchers = (clone $allQuery)->count();
        $unusedCount = (clone $allQuery)->where('status', 'unused')->count();
        $usedCount = (clone $allQuery)->where('status', 'used')->count();
        $unreportedUsedCount = (clone $allQuery)
            ->where('status', 'used')
            ->where('is_reported', false)
            ->count();
        $reportedUsedCount = (clone $allQuery)
            ->where('status', 'used')
            ->where('is_reported', true)
            ->count();
        $totalUsedAmount = (int) (clone $allQuery)
            ->where('status', 'used')
            ->sum('amount');
        $unreportedUsedAmount = (int) (clone $allQuery)
            ->where('status', 'used')
            ->where('is_reported', false)
            ->sum('amount');

        $partners = Voucher::select('partner_name')
            ->distinct()
            ->orderBy('partner_name')
            ->pluck('partner_name')
            ->values();

        // Ringkasan per mitra untuk laporan
        $partnerSummaries = Voucher::selectRaw(
            "partner_name,
             COUNT(*) as total_count,
             SUM(CASE WHEN status = 'unused' THEN 1 ELSE 0 END) as unused_count,
             SUM(CASE WHEN status = 'used' THEN 1 ELSE 0 END) as used_count,
             SUM(CASE WHEN status = 'used' AND is_reported = 0 THEN 1 ELSE 0 END) as unreported_count,
             SUM(CASE WHEN status = 'used' THEN amount ELSE 0 END) as used_amount,
             SUM(CASE WHEN status = 'used' AND is_reported = 0 THEN amount ELSE 0 END) as unreported_amount"
        )
            ->groupBy('partner_name')
            ->orderBy('partner_name')
            ->get()
            ->map(fn ($row) => [
                'partner_name' => $row->partner_name,
                'total_count' => (int) $row->total_count,
                'unused_count' => (int) $row->unused_count,
                'used_count' => (int) $row->used_count,
                'unreported_count' => (int) $row->unreported_count,
                'used_amount' => (int) $row->used_amount,
                'unreported_amount' => (int) $row->unreported_amount,
            ])
            ->values();

        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
        }
        $voucherPromoMode = data_get($tenant, 'voucher_promo_mode', 'both') ?: 'both';

        return response()->json([
            'status' => true,
            'data' => [
                'voucher_promo_mode' => $voucherPromoMode,
                'vouchers' => $vouchers->map(fn (Voucher $v) => [
                    'id' => $v->id,
                    'partner_name' => $v->partner_name,
                    'code' => $v->code,
                    'amount' => (int) $v->amount,
                    'status' => $v->status,
                    'order_id' => $v->order_id,
                    'order_code' => $v->order_code,
                    'used_by_name' => $v->used_by_name,
                    'used_by_phone' => $v->used_by_phone,
                    'used_at' => $v->used_at?->toIso8601String(),
                    'is_reported' => (bool) $v->is_reported,
                    'reported_at' => $v->reported_at?->toIso8601String(),
                    'notes' => $v->notes,
                    'created_at' => $v->created_at?->toIso8601String(),
                ])->values(),
                'summary' => [
                    'total_vouchers' => $totalVouchers,
                    'unused_count' => $unusedCount,
                    'used_count' => $usedCount,
                    'unreported_used_count' => $unreportedUsedCount,
                    'reported_used_count' => $reportedUsedCount,
                    'total_used_amount' => $totalUsedAmount,
                    'unreported_used_amount' => $unreportedUsedAmount,
                ],
                'partners' => $partners,
                'partner_summaries' => $partnerSummaries,
            ],
        ]);
    }

    /**
     * Admin endpoint: Import banyak nomor/kode voucher sekaligus (paste teks / CSV)
     */
    public function import(Request $request)
    {
        $request->validate([
            'partner_name' => ['required', 'string', 'max:120'],
            'amount' => ['required', 'integer', 'min:0'],
            'codes_text' => ['nullable', 'string'],
            'codes' => ['nullable', 'array'],
            'notes' => ['nullable', 'string', 'max:255'],
        ], [
            'partner_name.required' => 'Nama pihak kerjasama / program wajib diisi.',
            'amount.required' => 'Nominal potongan voucher wajib diisi.',
        ]);

        $partnerName = trim((string) $request->partner_name);
        $defaultAmount = max(0, (int) $request->amount);
        $notes = $request->filled('notes') ? trim((string) $request->notes) : null;
        $tenantId = app()->has('tenant') ? app('tenant')->id : ($request->user()?->tenant_id);

        $entries = [];

        if ($request->filled('codes') && is_array($request->codes)) {
            foreach ($request->codes as $item) {
                if (is_string($item)) {
                    $entries[] = ['code' => strtoupper(trim($item)), 'amount' => $defaultAmount];
                } elseif (is_array($item) && ! empty($item['code'])) {
                    $entries[] = [
                        'code' => strtoupper(trim((string) $item['code'])),
                        'amount' => isset($item['amount']) ? max(0, (int) $item['amount']) : $defaultAmount,
                    ];
                }
            }
        }

        if ($request->filled('codes_text')) {
            $lines = preg_split('/\r\n|\r|\n/', (string) $request->codes_text);
            foreach ($lines as $line) {
                $line = trim($line);
                if ($line === '') {
                    continue;
                }

                // Cek apakah format CSV "KODE,NOMINAL" atau "KODE;NOMINAL" atau "KODE\tNOMINAL"
                if (preg_match('/^([A-Za-z0-9\-_\/\.]+)\s*[,;\t]\s*(\d+)$/', $line, $matches)) {
                    $code = strtoupper(trim($matches[1]));
                    $amt = max(0, (int) $matches[2]);
                    if ($code !== '' && strtolower($code) !== 'code' && strtolower($code) !== 'kode') {
                        $entries[] = ['code' => $code, 'amount' => $amt];
                    }
                    continue;
                }

                // Jika satu baris berisi beberapa kode dipisahkan koma/titik koma
                $parts = preg_split('/[,;]+/', $line);
                foreach ($parts as $part) {
                    $cleanCode = strtoupper(trim($part));
                    if ($cleanCode !== '' && strtolower($cleanCode) !== 'code' && strtolower($cleanCode) !== 'kode') {
                        $entries[] = ['code' => $cleanCode, 'amount' => $defaultAmount];
                    }
                }
            }
        }

        // Hilangkan duplikat di dalam input yang sama
        $uniqueEntries = collect($entries)
            ->filter(fn ($e) => $e['code'] !== '')
            ->unique('code')
            ->values();

        if ($uniqueEntries->isEmpty()) {
            return response()->json([
                'status' => false,
                'message' => 'Tidak ada kode voucher valid untuk di-import.',
            ], 422);
        }

        $existingCodes = Voucher::whereIn('code', $uniqueEntries->pluck('code')->all())
            ->pluck('code')
            ->map(fn ($c) => strtoupper($c))
            ->flip();

        $importedCount = 0;
        $skippedCount = 0;
        $now = now();
        $insertBatch = [];

        foreach ($uniqueEntries as $entry) {
            if ($existingCodes->has($entry['code'])) {
                $skippedCount++;
                continue;
            }
            $insertBatch[] = [
                'tenant_id' => $tenantId,
                'partner_name' => $partnerName,
                'code' => $entry['code'],
                'amount' => $entry['amount'],
                'status' => 'unused',
                'is_reported' => false,
                'notes' => $notes,
                'created_at' => $now,
                'updated_at' => $now,
            ];
            $importedCount++;
        }

        if (! empty($insertBatch)) {
            foreach (array_chunk($insertBatch, 200) as $chunk) {
                Voucher::insert($chunk);
            }
        }

        return response()->json([
            'status' => true,
            'message' => "Berhasil mengimport {$importedCount} voucher" . ($skippedCount > 0 ? " ({$skippedCount} kode duplikat dilewati)." : '.'),
            'data' => [
                'imported_count' => $importedCount,
                'skipped_count' => $skippedCount,
            ],
        ], 201);
    }

    /**
     * Tandai voucher yang sudah terpakai sebagai sudah dilaporkan (atau batal dilaporkan) ke mitra
     */
    public function markReported(Request $request)
    {
        $request->validate([
            'voucher_ids' => ['nullable', 'array'],
            'voucher_ids.*' => ['integer'],
            'partner_name' => ['nullable', 'string'],
            'is_reported' => ['nullable', 'boolean'],
        ]);

        $isReported = $request->has('is_reported') ? (bool) $request->boolean('is_reported') : true;

        $query = Voucher::where('status', 'used');

        if ($request->filled('voucher_ids') && is_array($request->voucher_ids)) {
            $query->whereIn('id', $request->voucher_ids);
        } elseif ($request->filled('partner_name') && $request->partner_name !== 'ALL') {
            $query->where('partner_name', $request->partner_name);
        }

        $updatedCount = $query->update([
            'is_reported' => $isReported,
            'reported_at' => $isReported ? now() : null,
        ]);

        return response()->json([
            'status' => true,
            'message' => $isReported
                ? "{$updatedCount} voucher ditandai sudah dilaporkan."
                : "{$updatedCount} voucher dikembalikan ke status belum dilaporkan.",
            'data' => [
                'updated_count' => $updatedCount,
            ],
        ]);
    }

    public function destroy(Voucher $voucher)
    {
        $voucher->delete();

        return response()->json([
            'status' => true,
            'message' => 'Voucher berhasil dihapus.',
        ]);
    }

    public function bulkDestroy(Request $request)
    {
        $request->validate([
            'voucher_ids' => ['nullable', 'array'],
            'voucher_ids.*' => ['integer'],
            'partner_name' => ['nullable', 'string'],
            'status' => ['nullable', 'string', 'in:unused,used'],
        ]);

        $query = Voucher::query();

        if ($request->filled('voucher_ids') && is_array($request->voucher_ids)) {
            $query->whereIn('id', $request->voucher_ids);
        } else {
            if ($request->filled('partner_name') && $request->partner_name !== 'ALL') {
                $query->where('partner_name', $request->partner_name);
            }
            if ($request->filled('status')) {
                $query->where('status', $request->status);
            }
        }

        $deletedCount = $query->delete();

        return response()->json([
            'status' => true,
            'message' => "{$deletedCount} voucher berhasil dihapus.",
            'data' => [
                'deleted_count' => $deletedCount,
            ],
        ]);
    }
}
