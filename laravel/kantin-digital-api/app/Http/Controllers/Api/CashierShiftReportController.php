<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CashierShiftReport;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CashierShiftReportController extends Controller
{
    /**
     * Data akumulasi waktu buka berjalan (current running shift)
     */
    public function currentShift(Request $request)
    {
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
        }

        $paidStatuses = ['PAID', 'PROCESSING', 'READY', 'SERVED'];

        // Pesanan berjalan: belum pernah dilaporkan dalam shift report (cashier_shift_report_id IS NULL)
        $unreportedQuery = Order::whereNull('cashier_shift_report_id');

        $activeOrders = (clone $unreportedQuery)
            ->whereIn('status', $paidStatuses)
            ->get();

        $unpaidOrders = (clone $unreportedQuery)
            ->where('status', 'UNPAID')
            ->get();

        $cashExpected = (float) $activeOrders->where('payment_method', 'cash')->sum('total_amount');
        $qrisExpected = (float) $activeOrders->where('payment_method', 'qris')->sum('total_amount');
        $totalSalesExpected = $cashExpected + $qrisExpected;

        // Cek laporan yang sedang menunggu ACC (PENDING)
        $pendingReport = CashierShiftReport::with(['cashier:id,name', 'approver:id,name'])
            ->where('status', 'PENDING')
            ->latest()
            ->first();

        // Riwayat laporan terakhir
        $recentReports = CashierShiftReport::with(['cashier:id,name', 'approver:id,name'])
            ->latest()
            ->limit(10)
            ->get();

        return response()->json([
            'status' => true,
            'data' => [
                'is_store_open' => (bool) data_get($tenant, 'is_store_open', false),
                'store_opened_at' => data_get($tenant, 'store_opened_at'),
                'total_orders' => $activeOrders->count(),
                'cash_orders_count' => $activeOrders->where('payment_method', 'cash')->count(),
                'qris_orders_count' => $activeOrders->where('payment_method', 'qris')->count(),
                'total_cash_expected' => $cashExpected,
                'total_qris_expected' => $qrisExpected,
                'total_sales_expected' => $totalSalesExpected,
                'unpaid_orders_count' => $unpaidOrders->count(),
                'unpaid_amount' => (float) $unpaidOrders->sum('total_amount'),
                'pending_report' => $pendingReport,
                'recent_reports' => $recentReports,
            ],
        ]);
    }

    /**
     * Kasir melaporkan uang yang diterimanya (Submit Shift Report)
     */
    public function submitReport(Request $request)
    {
        $request->validate([
            'cash_received' => ['required', 'numeric', 'min:0'],
            'cashier_notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $tenant = app()->has('tenant') ? app('tenant') : null;
        if (! $tenant && $request->user() && $request->user()->tenant_id) {
            $tenant = \App\Models\Tenant::find($request->user()->tenant_id);
        }

        $paidStatuses = ['PAID', 'PROCESSING', 'READY', 'SERVED'];

        $report = DB::transaction(function () use ($request, $tenant, $paidStatuses) {
            $unreportedOrders = Order::whereNull('cashier_shift_report_id')
                ->whereIn('status', $paidStatuses)
                ->lockForUpdate()
                ->get();

            $totalOrders = $unreportedOrders->count();
            $cashExpected = (float) $unreportedOrders->where('payment_method', 'cash')->sum('total_amount');
            $qrisExpected = (float) $unreportedOrders->where('payment_method', 'qris')->sum('total_amount');
            $totalSalesExpected = $cashExpected + $qrisExpected;

            $cashReceived = (float) $request->cash_received;
            $cashDifference = $cashReceived - $cashExpected;

            $openedAt = data_get($tenant, 'store_opened_at')
                ? \Carbon\Carbon::parse(data_get($tenant, 'store_opened_at'))
                : now()->startOfDay();

            $report = CashierShiftReport::create([
                'tenant_id' => data_get($tenant, 'id', 1),
                'cashier_id' => $request->user()->id,
                'shift_opened_at' => $openedAt,
                'shift_closed_at' => now(),
                'total_orders' => $totalOrders,
                'total_cash_expected' => $cashExpected,
                'total_qris_expected' => $qrisExpected,
                'total_sales_expected' => $totalSalesExpected,
                'cash_received' => $cashReceived,
                'cash_difference' => $cashDifference,
                'status' => 'PENDING',
                'cashier_notes' => $request->cashier_notes,
            ]);

            if ($unreportedOrders->isNotEmpty()) {
                Order::whereIn('id', $unreportedOrders->pluck('id'))
                    ->update(['cashier_shift_report_id' => $report->id]);
            }

            return $report;
        });

        $report->load(['cashier:id,name']);

        return response()->json([
            'status' => true,
            'message' => 'Laporan uang shift berhasil dikirim dan menunggu ACC dari Admin/Manajer.',
            'data' => $report,
        ], 201);
    }

    /**
     * Daftar laporan shift kasir
     */
    public function index(Request $request)
    {
        $query = CashierShiftReport::with(['cashier:id,name', 'approver:id,name']);

        if ($request->filled('status')) {
            $query->where('status', strtoupper($request->status));
        }

        $limit = $request->integer('limit', 20);
        $reports = $query->latest()->paginate($limit);

        return response()->json([
            'status' => true,
            'data' => $reports->items(),
            'current_page' => $reports->currentPage(),
            'last_page' => $reports->lastPage(),
            'total' => $reports->total(),
        ]);
    }

    /**
     * Admin/Manajer melakukan ACC / persetujuan setoran uang kasir
     */
    public function approve(Request $request, $id)
    {
        $report = CashierShiftReport::findOrFail($id);

        if ($report->status === 'APPROVED') {
            return response()->json([
                'status' => false,
                'message' => 'Laporan ini sudah pernah di-ACC sebelumnya.',
            ], 422);
        }

        $report->update([
            'status' => 'APPROVED',
            'approved_by' => $request->user()->id,
            'approved_at' => now(),
            'approval_notes' => $request->input('notes'),
        ]);

        $report->load(['cashier:id,name', 'approver:id,name']);

        return response()->json([
            'status' => true,
            'message' => 'Laporan uang kasir berhasil di-ACC!',
            'data' => $report,
        ]);
    }

    /**
     * Admin/Manajer menolak setoran kasir (misal salah hitung)
     */
    public function reject(Request $request, $id)
    {
        $report = CashierShiftReport::findOrFail($id);

        DB::transaction(function () use ($report, $request) {
            $report->update([
                'status' => 'REJECTED',
                'approved_by' => $request->user()->id,
                'approved_at' => now(),
                'approval_notes' => $request->input('notes', 'Setoran ditolak, silakan hitung ulang.'),
            ]);

            // Kembalikan pesanan agar belum terasosiasi shift report, sehingga masuk kembali ke akumulasi
            Order::where('cashier_shift_report_id', $report->id)
                ->update(['cashier_shift_report_id' => null]);
        });

        $report->load(['cashier:id,name', 'approver:id,name']);

        return response()->json([
            'status' => true,
            'message' => 'Laporan kasir ditolak. Transaksi dikembalikan ke shift berjalan agar kasir dapat melaporkan ulang.',
            'data' => $report,
        ]);
    }
}
