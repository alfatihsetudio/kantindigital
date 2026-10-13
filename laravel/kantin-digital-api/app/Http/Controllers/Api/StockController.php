<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockCheck;
use App\Models\StockCheckItem;
use App\Models\StockItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class StockController extends Controller
{
    // ==========================================
    // 1. MASTER STOCK ITEMS (DAFTAR BAHAN / BARANG)
    // ==========================================

    public function items(Request $request)
    {
        $query = StockItem::query();

        if ($request->boolean('active_only', true)) {
            $query->where('is_active', true);
        }

        $items = $query->orderBy('name', 'asc')->get();

        // Jika belum ada item sama sekali untuk tenant ini, sediakan starter items umum
        if ($items->isEmpty() && app()->has('tenant')) {
            $tenant = app('tenant');
            $defaultItems = [
                ['name' => 'Gula Merah', 'unit' => 'gram', 'category' => 'Bahan Baku'],
                ['name' => 'Gula Pasir', 'unit' => 'gram', 'category' => 'Bahan Baku'],
                ['name' => 'Bubuk Kopi / Biji Kopi', 'unit' => 'gram', 'category' => 'Bahan Baku'],
                ['name' => 'Susu UHT / Full Cream', 'unit' => 'ml', 'category' => 'Bahan Baku'],
                ['name' => 'Cup Minuman 16oz', 'unit' => 'pcs', 'category' => 'Kemasan'],
                ['name' => 'Sedotan', 'unit' => 'pcs', 'category' => 'Kemasan'],
            ];

            foreach ($defaultItems as $item) {
                StockItem::create(array_merge($item, ['is_active' => true]));
            }

            $items = StockItem::where('is_active', true)->orderBy('name', 'asc')->get();
        }

        return response()->json([
            'status' => true,
            'data' => $items,
        ]);
    }

    public function storeItem(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'unit' => 'required|string|max:50',
            'category' => 'nullable|string|max:100',
        ]);

        $item = StockItem::create([
            'name' => trim($request->name),
            'unit' => trim($request->unit),
            'category' => trim($request->category ?? 'Bahan Baku'),
            'is_active' => true,
        ]);

        return response()->json([
            'status' => true,
            'message' => 'Item stok berhasil ditambahkan',
            'data' => $item,
        ], 201);
    }

    public function updateItem(Request $request, $id)
    {
        $item = StockItem::find($id);
        if (! $item) {
            return response()->json(['status' => false, 'message' => 'Item tidak ditemukan'], 404);
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'unit' => 'sometimes|required|string|max:50',
            'category' => 'nullable|string|max:100',
            'is_active' => 'sometimes|boolean',
        ]);

        $item->update($request->only(['name', 'unit', 'category', 'is_active']));

        return response()->json([
            'status' => true,
            'message' => 'Item stok berhasil diperbarui',
            'data' => $item,
        ]);
    }

    public function destroyItem($id)
    {
        $item = StockItem::find($id);
        if (! $item) {
            return response()->json(['status' => false, 'message' => 'Item tidak ditemukan'], 404);
        }

        // Soft deactive jika sudah pernah dipakai di check items
        $hasUsage = StockCheckItem::where('stock_item_id', $id)->exists();
        if ($hasUsage) {
            $item->update(['is_active' => false]);
            return response()->json([
                'status' => true,
                'message' => 'Item dinonaktifkan karena telah memiliki riwayat catatan',
            ]);
        }

        $item->delete();
        return response()->json([
            'status' => true,
            'message' => 'Item berhasil dihapus',
        ]);
    }

    // ==========================================
    // 2. STOCK CHECKS (CLOSING & OPENING)
    // ==========================================

    /**
     * Mengambil catatan closing terakhir untuk dijadikan acuan saat buka toko (Opening)
     */
    public function latestClosing()
    {
        $latestClosing = StockCheck::with(['items', 'user'])
            ->where('check_type', 'closing')
            ->orderBy('created_at', 'desc')
            ->first();

        return response()->json([
            'status' => true,
            'data' => $latestClosing,
        ]);
    }

    /**
     * Riwayat catatan stok
     */
    public function indexChecks(Request $request)
    {
        $query = StockCheck::with(['user', 'items']);

        if ($request->filled('type')) {
            $query->where('check_type', $request->type);
        }

        if ($request->filled('date')) {
            $query->whereDate('check_date', $request->date);
        }

        $limit = $request->integer('limit', 30);
        $checks = $query->orderBy('created_at', 'desc')->paginate($limit);

        return response()->json([
            'status' => true,
            'data' => $checks->items(),
            'current_page' => $checks->currentPage(),
            'last_page' => $checks->lastPage(),
            'total' => $checks->total(),
        ]);
    }

    /**
     * Detail catatan stok
     */
    public function showCheck($id)
    {
        $check = StockCheck::with(['user', 'items.stockItem'])->find($id);

        if (! $check) {
            return response()->json(['status' => false, 'message' => 'Catatan stok tidak ditemukan'], 404);
        }

        return response()->json([
            'status' => true,
            'data' => $check,
        ]);
    }

    /**
     * Simpan catatan stok (Closing tutup toko atau Opening buka toko)
     */
    public function storeCheck(Request $request)
    {
        $request->validate([
            'check_type' => 'required|in:closing,opening',
            'check_date' => 'nullable|date',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.item_name' => 'required|string',
            'items.*.unit' => 'required|string',
            'items.*.whole_quantity' => 'nullable|numeric|min:0',
            'items.*.remainder_quantity' => 'nullable|numeric|min:0',
        ]);

        $user = $request->user();
        $checkType = $request->check_type;
        $checkDate = $request->check_date ?? now()->toDateString();
        $notes = $request->notes;
        $itemsData = $request->items;

        $check = DB::transaction(function () use ($user, $checkType, $checkDate, $notes, $itemsData) {
            $totalItems = count($itemsData);
            $matchedCount = 0;
            $hasDiscrepancy = false;

            $stockCheck = StockCheck::create([
                'user_id' => $user?->id,
                'check_type' => $checkType,
                'check_date' => $checkDate,
                'status' => 'completed',
                'total_items' => $totalItems,
                'matched_items' => 0,
                'notes' => $notes,
            ]);

            foreach ($itemsData as $row) {
                $whole = (float) ($row['whole_quantity'] ?? 0);
                $remainder = (float) ($row['remainder_quantity'] ?? 0);
                $prevWhole = isset($row['previous_whole_quantity']) && $row['previous_whole_quantity'] !== '' ? (float) $row['previous_whole_quantity'] : null;
                $prevRemainder = isset($row['previous_remainder_quantity']) && $row['previous_remainder_quantity'] !== '' ? (float) $row['previous_remainder_quantity'] : null;

                $diffWhole = 0;
                $diffRemainder = 0;
                $isMatched = true;

                if ($checkType === 'opening' && ($prevWhole !== null || $prevRemainder !== null)) {
                    if ($prevWhole !== null) {
                        $diffWhole = round($whole - $prevWhole, 2);
                    }
                    if ($prevRemainder !== null) {
                        $diffRemainder = round($remainder - $prevRemainder, 2);
                    }

                    if (abs($diffWhole) > 0.001 || abs($diffRemainder) > 0.001) {
                        $isMatched = false;
                        $hasDiscrepancy = true;
                    }
                }

                if ($isMatched) {
                    $matchedCount++;
                }

                StockCheckItem::create([
                    'stock_check_id' => $stockCheck->id,
                    'stock_item_id' => $row['stock_item_id'] ?? null,
                    'item_name' => trim($row['item_name']),
                    'unit' => trim($row['unit'] ?? 'gram'),
                    'whole_quantity' => $whole,
                    'remainder_quantity' => $remainder,
                    'previous_whole_quantity' => $prevWhole,
                    'previous_remainder_quantity' => $prevRemainder,
                    'difference_whole' => $diffWhole,
                    'difference_remainder' => $diffRemainder,
                    'is_matched' => $isMatched,
                    'notes' => $row['notes'] ?? null,
                ]);
            }

            $stockCheck->update([
                'matched_items' => $matchedCount,
                'status' => ($checkType === 'opening' && $hasDiscrepancy) ? 'has_difference' : 'completed',
            ]);

            return $stockCheck->load(['items', 'user']);
        });

        $message = $checkType === 'closing'
            ? 'Catatan stok tutup usaha berhasil disimpan'
            : ($check->status === 'has_difference'
                ? 'Catatan stok buka toko disimpan dengan catatan selisih'
                : 'Pemeriksaan stok buka toko sesuai dengan catatan kemarin');

        return response()->json([
            'status' => true,
            'message' => $message,
            'data' => $check,
        ], 201);
    }
}
