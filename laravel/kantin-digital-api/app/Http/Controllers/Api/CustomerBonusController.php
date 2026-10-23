<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomerBonus;
use App\Models\CustomerBonusLog;
use App\Models\Tenant;
use App\Services\CustomerBonusService;
use Illuminate\Http\Request;

class CustomerBonusController extends Controller
{
    /**
     * Public check for a phone number's current loyalty / bonus status
     */
    public function check(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = Tenant::find($request->user()->tenant_id);
        }

        if (! $tenant) {
            return response()->json([
                'status' => false,
                'message' => 'Tenant tidak ditemukan.',
            ], 404);
        }

        $phone = CustomerBonusService::normalizePhone($request->query('phone') ?? $request->input('phone'));
        $bonus = null;
        $isRegistered = false;
        $bonusPercent = 0;

        if (! empty($phone)) {
            $bonusRecord = CustomerBonus::withoutGlobalScopes()
                ->where('tenant_id', $tenant->id)
                ->where('customer_phone', $phone)
                ->first();

            if ($bonusRecord && $bonusRecord->is_active && (int) $bonusRecord->bonus_percent > 0) {
                $isRegistered = true;
                $bonusPercent = (int) $bonusRecord->bonus_percent;
                $bonus = [
                    'id' => $bonusRecord->id,
                    'customer_name' => $bonusRecord->customer_name,
                    'customer_phone' => $bonusRecord->customer_phone,
                    'bonus_percent' => $bonusPercent,
                    'is_active' => (bool) $bonusRecord->is_active,
                    'notes' => $bonusRecord->notes,
                    'total_orders' => $bonusRecord->total_orders,
                    'total_spend' => $bonusRecord->total_spend,
                    'total_bonus_earned' => $bonusRecord->total_bonus_earned,
                    'total_bonus_claimed' => $bonusRecord->total_bonus_claimed,
                    'bonus_balance' => $bonusRecord->bonus_balance,
                    'last_order_at' => $bonusRecord->last_order_at?->toIso8601String(),
                ];
            }
        }

        return response()->json([
            'status' => true,
            'data' => [
                'is_active' => (bool) $tenant->is_customer_bonus_active,
                'is_registered' => $isRegistered,
                'bonus_percent' => $bonusPercent,
                'min_spend' => (int) ($tenant->customer_bonus_min_spend ?? 0),
                'phone' => $phone,
                'bonus' => $bonus,
            ],
        ]);
    }

    /**
     * List all customer bonuses for tenant (Admin & Cashier)
     */
    public function index(Request $request)
    {
        $tenantId = app()->has('tenant') ? app('tenant')->id : $request->user()->tenant_id;

        $query = CustomerBonus::withoutGlobalScopes()
            ->where('tenant_id', $tenantId);

        if ($request->filled('search')) {
            $search = trim((string) $request->input('search'));
            $cleanSearch = CustomerBonusService::normalizePhone($search);
            $query->where(function ($q) use ($search, $cleanSearch) {
                $q->where('customer_phone', 'like', "%{$search}%")
                  ->orWhere('customer_name', 'like', "%{$search}%")
                  ->orWhere('notes', 'like', "%{$search}%");
                if (! empty($cleanSearch)) {
                    $q->orWhere('customer_phone', 'like', "%{$cleanSearch}%");
                }
            });
        }

        if ($request->boolean('with_balance_only')) {
            $query->where('bonus_balance', '>', 0);
        }

        // Summary aggregations
        $baseQuery = CustomerBonus::withoutGlobalScopes()->where('tenant_id', $tenantId);
        $summary = [
            'total_customers' => (int) $baseQuery->count(),
            'total_spend' => (int) $baseQuery->sum('total_spend'),
            'total_bonus_earned' => (int) $baseQuery->sum('total_bonus_earned'),
            'total_bonus_claimed' => (int) $baseQuery->sum('total_bonus_claimed'),
            'total_bonus_balance' => (int) $baseQuery->sum('bonus_balance'),
        ];

        $sortBy = in_array($request->input('sort_by'), ['bonus_percent', 'bonus_balance', 'total_spend', 'total_orders', 'last_order_at', 'created_at'], true)
            ? $request->input('sort_by')
            : 'id';
        $sortOrder = strtolower($request->input('sort_order', 'desc')) === 'asc' ? 'asc' : 'desc';

        $perPage = min(100, max(5, (int) $request->input('per_page', 50)));
        $paginated = $query->orderBy($sortBy, $sortOrder)->paginate($perPage);

        return response()->json([
            'status' => true,
            'summary' => $summary,
            'data' => $paginated->items(),
            'meta' => [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
        ]);
    }

    /**
     * Daftarkan nomor HP konsumen tertentu ke program bonus (Admin & Kasir)
     */
    public function store(Request $request)
    {
        $tenantId = app()->has('tenant') ? app('tenant')->id : $request->user()->tenant_id;

        $request->validate([
            'customer_phone' => ['required', 'string', 'max:30'],
            'customer_name' => ['nullable', 'string', 'max:100'],
            'bonus_percent' => ['required', 'integer', 'min:1', 'max:100'],
            'notes' => ['nullable', 'string', 'max:255'],
        ]);

        $phone = CustomerBonusService::normalizePhone($request->customer_phone);
        if (empty($phone)) {
            return response()->json([
                'status' => false,
                'message' => 'Nomor HP tidak valid.',
            ], 422);
        }

        $exists = CustomerBonus::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('customer_phone', $phone)
            ->first();

        if ($exists) {
            return response()->json([
                'status' => false,
                'message' => 'Nomor HP ' . $phone . ' sudah terdaftar dalam daftar konsumen bonus.',
            ], 422);
        }

        $bonus = CustomerBonus::create([
            'tenant_id' => $tenantId,
            'customer_phone' => $phone,
            'customer_name' => $request->customer_name ?: null,
            'bonus_percent' => (int) $request->bonus_percent,
            'is_active' => true,
            'notes' => $request->notes ?: null,
            'total_orders' => 0,
            'total_spend' => 0,
            'total_bonus_earned' => 0,
            'total_bonus_claimed' => 0,
            'bonus_balance' => 0,
        ]);

        return response()->json([
            'status' => true,
            'message' => "Konsumen {$bonus->customer_phone} berhasil didaftarkan dengan bonus {$bonus->bonus_percent}%.",
            'data' => $bonus,
        ], 201);
    }

    /**
     * Update data konsumen bonus (ubah nama, persentase bonus, status aktif, atau catatan)
     */
    public function update(Request $request, int $id)
    {
        $tenantId = app()->has('tenant') ? app('tenant')->id : $request->user()->tenant_id;

        $bonus = CustomerBonus::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('id', $id)
            ->firstOrFail();

        $request->validate([
            'customer_name' => ['nullable', 'string', 'max:100'],
            'bonus_percent' => ['required', 'integer', 'min:1', 'max:100'],
            'is_active' => ['nullable', 'boolean'],
            'notes' => ['nullable', 'string', 'max:255'],
        ]);

        $bonus->update([
            'customer_name' => $request->has('customer_name') ? $request->customer_name : $bonus->customer_name,
            'bonus_percent' => (int) $request->bonus_percent,
            'is_active' => $request->has('is_active') ? $request->boolean('is_active') : $bonus->is_active,
            'notes' => $request->has('notes') ? $request->notes : $bonus->notes,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Data konsumen bonus berhasil diperbarui.',
            'data' => $bonus,
        ]);
    }

    /**
     * Hapus konsumen dari program bonus
     */
    public function destroy(Request $request, int $id)
    {
        $tenantId = app()->has('tenant') ? app('tenant')->id : $request->user()->tenant_id;

        $bonus = CustomerBonus::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('id', $id)
            ->firstOrFail();

        $bonus->logs()->delete();
        $bonus->delete();

        return response()->json([
            'status' => true,
            'message' => 'Konsumen berhasil dihapus dari program bonus.',
        ]);
    }

    /**
     * Show mutation history for a specific customer bonus
     */
    public function logs(Request $request, int $id)
    {
        $tenantId = app()->has('tenant') ? app('tenant')->id : $request->user()->tenant_id;

        $bonus = CustomerBonus::withoutGlobalScopes()
            ->where('tenant_id', $tenantId)
            ->where('id', $id)
            ->firstOrFail();

        $logs = CustomerBonusLog::withoutGlobalScopes()
            ->with('user:id,name')
            ->where('tenant_id', $tenantId)
            ->where('customer_bonus_id', $id)
            ->orderByDesc('id')
            ->paginate(50);

        return response()->json([
            'status' => true,
            'bonus' => $bonus,
            'data' => $logs->items(),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'per_page' => $logs->perPage(),
                'total' => $logs->total(),
            ],
        ]);
    }

    /**
     * Claim / withdraw bonus
     */
    public function claim(Request $request, int $id, CustomerBonusService $service)
    {
        $request->validate([
            'amount' => ['required', 'integer', 'min:1'],
            'notes' => ['nullable', 'string', 'max:255'],
        ]);

        $tenantId = app()->has('tenant') ? app('tenant')->id : $request->user()->tenant_id;
        $userId = $request->user()?->id;

        $bonus = $service->claimBonus(
            tenantId: $tenantId,
            customerBonusId: $id,
            claimAmount: (int) $request->input('amount'),
            notes: $request->input('notes'),
            userId: $userId
        );

        return response()->json([
            'status' => true,
            'message' => 'Bonus sebesar Rp ' . number_format($request->input('amount'), 0, ',', '.') . ' berhasil dicairkan.',
            'data' => $bonus,
        ]);
    }
}
