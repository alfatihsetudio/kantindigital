<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentWebhookController extends Controller
{
    /**
     * Handle incoming payment notification from Android Notification Reader (e.g. DANA Bisnis, BCA, GoPay, etc.)
     */
    public function handle(Request $request)
    {
        $rawMessage = $request->input('message') ?? $request->input('text') ?? $request->input('title') ?? json_encode($request->all());
        $amount = $request->input('amount');

        Log::info('Payment notification webhook received:', [
            'payload' => $request->all(),
        ]);

        // If amount is not explicitly provided, extract from message text (e.g. "Rp35.000 diterima DANA Bisnis")
        if (!$amount && $rawMessage) {
            if (preg_match('/Rp\s*([0-9\.\,]+)/i', $rawMessage, $matches)) {
                $cleanNumber = preg_replace('/[^0-9]/', '', $matches[1]);
                $amount = (int) $cleanNumber;
            }
        }

        if (!$amount || $amount <= 0) {
            return response()->json([
                'status' => false,
                'message' => 'Nominal transaksi tidak terdeteksi dalam notifikasi.',
                'raw' => $rawMessage,
            ], 422);
        }

        // Look for the most recent UNPAID order with matching amount created within last 60 minutes
        $order = Order::where('status', 'UNPAID')
            ->where('total_amount', $amount)
            ->where('created_at', '>=', now()->subMinutes(60))
            ->orderByDesc('created_at')
            ->first();

        if ($order) {
            $order->update(['status' => 'PAID']);
            app(\App\Services\CustomerBonusService::class)->recordOrderBonus($order->fresh());

            // Jika ini invoice registrasi toko (#INV-...), aktifkan tenant terkait
            if (str_starts_with($order->code, 'INV-')) {
                $tenant = \App\Models\Tenant::where('whatsapp', $order->customer_phone)
                    ->orWhere('phone', $order->customer_phone)
                    ->latest()
                    ->first();
                if ($tenant) {
                    $tenant->update(['is_active' => true]);
                    Log::info("Tenant {$tenant->subdomain} otomatis diaktifkan setelah pelunasan invoice #{$order->code}.");
                }
            }

            Log::info("Order #{$order->code} automatically marked as PAID from notification webhook ($amount).");

            return response()->json([
                'status' => true,
                'message' => "Pesanan #{$order->code} berhasil diubah otomatis menjadi PAID.",
                'data' => [
                    'order_code' => $order->code,
                    'customer_name' => $order->customer_name,
                    'amount' => $order->total_amount,
                    'status' => $order->status,
                ],
            ]);
        }

        return response()->json([
            'status' => false,
            'message' => "Tidak ada pesanan UNPAID dengan nominal Rp " . number_format($amount, 0, ',', '.') . " yang cocok dalam 60 menit terakhir.",
            'amount' => $amount,
        ], 404);
    }
}
