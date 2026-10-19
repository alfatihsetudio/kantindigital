<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    /**
     * Daftar belanja / pengeluaran.
     * Bisa difilter berdasarkan rentang tanggal & kategori.
     */
    public function index(Request $request)
    {
        $query = Expense::with(['user:id,name']);

        if ($request->filled('start_date')) {
            $query->whereDate('expense_date', '>=', $request->start_date);
        }

        if ($request->filled('end_date')) {
            $query->whereDate('expense_date', '<=', $request->end_date);
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        $totalAmount = (float) (clone $query)->sum('amount');
        $totalTransactions = (clone $query)->count();

        $limit = $request->integer('limit', 50);
        $expenses = $query->orderByDesc('expense_date')
            ->orderByDesc('id')
            ->paginate($limit);

        return response()->json([
            'status' => true,
            'data' => $expenses->items(),
            'summary' => [
                'total_amount' => $totalAmount,
                'total_transactions' => $totalTransactions,
            ],
            'current_page' => $expenses->currentPage(),
            'last_page' => $expenses->lastPage(),
            'total' => $expenses->total(),
        ]);
    }

    /**
     * Kasir / operasional mencatat pengeluaran baru.
     */
    public function store(Request $request)
    {
        $request->validate([
            'expense_date' => 'required|date',
            'category' => 'required|string|max:100',
            'description' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0',
            'notes' => 'nullable|string|max:1000',
        ]);

        $expense = Expense::create([
            'user_id' => $request->user()?->id,
            'expense_date' => $request->expense_date,
            'category' => trim($request->category),
            'description' => trim($request->description),
            'amount' => $request->amount,
            'notes' => $request->notes,
        ]);

        $expense->load(['user:id,name']);

        return response()->json([
            'status' => true,
            'message' => 'Pengeluaran berhasil dicatat',
            'data' => $expense,
        ], 201);
    }

    /**
     * Perbarui catatan pengeluaran (koreksi input kasir).
     */
    public function update(Request $request, $id)
    {
        $expense = Expense::find($id);

        if (! $expense) {
            return response()->json(['status' => false, 'message' => 'Data pengeluaran tidak ditemukan'], 404);
        }

        $request->validate([
            'expense_date' => 'sometimes|required|date',
            'category' => 'sometimes|required|string|max:100',
            'description' => 'sometimes|required|string|max:255',
            'amount' => 'sometimes|required|numeric|min:0',
            'notes' => 'nullable|string|max:1000',
        ]);

        $expense->update($request->only(['expense_date', 'category', 'description', 'amount', 'notes']));
        $expense->load(['user:id,name']);

        return response()->json([
            'status' => true,
            'message' => 'Pengeluaran berhasil diperbarui',
            'data' => $expense,
        ]);
    }

    /**
     * Hapus catatan pengeluaran.
     */
    public function destroy($id)
    {
        $expense = Expense::find($id);

        if (! $expense) {
            return response()->json(['status' => false, 'message' => 'Data pengeluaran tidak ditemukan'], 404);
        }

        $expense->delete();

        return response()->json([
            'status' => true,
            'message' => 'Pengeluaran berhasil dihapus',
        ]);
    }
}
