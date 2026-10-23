<?php

namespace App\Services;

use App\Models\CustomerBonus;
use App\Models\CustomerBonusLog;
use App\Models\Order;
use App\Models\Tenant;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\ValidationException;

class CustomerBonusService
{
    /**
     * Standardize phone number format (digits only, e.g. 08123456789)
     */
    public static function normalizePhone(?string $phone): string
    {
        if (empty($phone)) {
            return '';
        }

        $cleaned = preg_replace('/[^0-9]/', '', $phone);
        if (str_starts_with($cleaned, '62')) {
            $cleaned = '0' . substr($cleaned, 2);
        }

        return $cleaned;
    }

    /**
     * Record bonus for a paid order
     */
    public function recordOrderBonus(Order $order): ?CustomerBonusLog
    {
        $phone = self::normalizePhone($order->customer_phone);
        if (empty($phone)) {
            return null;
        }

        if (! in_array($order->status, ['PAID', 'PROCESSING', 'READY', 'SERVED'], true)) {
            return null;
        }

        $tenant = Tenant::find($order->tenant_id);
        if (! $tenant || ! $tenant->is_customer_bonus_active) {
            return null;
        }

        $minSpend = (int) ($tenant->customer_bonus_min_spend ?? 0);
        if ((int) $order->total_amount < $minSpend) {
            return null;
        }

        // Hanya konsumen tertentu yang telah didaftarkan manual oleh Admin yang berhak menerima bonus
        $bonus = CustomerBonus::withoutGlobalScopes()
            ->where('tenant_id', $order->tenant_id)
            ->where('customer_phone', $phone)
            ->first();

        if (! $bonus || ! $bonus->is_active || (int) $bonus->bonus_percent <= 0) {
            return null;
        }

        // Idempotency: check if earn log already recorded for this order
        $alreadyLogged = CustomerBonusLog::withoutGlobalScopes()
            ->where('tenant_id', $order->tenant_id)
            ->where('order_id', $order->id)
            ->where('type', 'earn')
            ->exists();

        if ($alreadyLogged) {
            return null;
        }

        $percent = (int) $bonus->bonus_percent;
        $bonusAmount = (int) floor(($order->total_amount * $percent) / 100);

        if ($bonusAmount <= 0) {
            return null;
        }

        return DB::transaction(function () use ($order, $tenant, $phone, $percent, $bonusAmount) {
            $bonus = CustomerBonus::withoutGlobalScopes()
                ->where('tenant_id', $order->tenant_id)
                ->where('customer_phone', $phone)
                ->lockForUpdate()
                ->first();

            if (! $bonus || ! $bonus->is_active) {
                return null;
            }

            if (! empty($order->customer_name) && empty($bonus->customer_name)) {
                $bonus->customer_name = $order->customer_name;
            }

            $bonus->total_orders += 1;
            $bonus->total_spend += (int) $order->total_amount;
            $bonus->total_bonus_earned += $bonusAmount;
            $bonus->bonus_balance += $bonusAmount;
            $bonus->last_order_at = now();
            $bonus->save();

            $log = CustomerBonusLog::create([
                'tenant_id' => $order->tenant_id,
                'customer_bonus_id' => $bonus->id,
                'customer_phone' => $phone,
                'order_id' => $order->id,
                'order_code' => $order->code,
                'type' => 'earn',
                'transaction_amount' => (int) $order->total_amount,
                'bonus_percent' => $percent,
                'bonus_amount' => $bonusAmount,
                'balance_after' => $bonus->bonus_balance,
                'notes' => "Bonus {$percent}% dari transaksi #{$order->code} (Rp " . number_format($order->total_amount, 0, ',', '.') . ")",
            ]);

            $order->updateQuietly(['bonus_amount' => $bonusAmount]);

            Log::info("Customer bonus credited: phone={$phone}, bonus={$bonusAmount}, order=#{$order->code}");

            return $log;
        });
    }

    /**
     * Rollback bonus if a previously PAID order is cancelled
     */
    public function cancelOrderBonus(Order $order): ?CustomerBonusLog
    {
        $phone = self::normalizePhone($order->customer_phone);
        if (empty($phone)) {
            return null;
        }

        $earnLog = CustomerBonusLog::withoutGlobalScopes()
            ->where('tenant_id', $order->tenant_id)
            ->where('order_id', $order->id)
            ->where('type', 'earn')
            ->first();

        if (! $earnLog) {
            return null;
        }

        $alreadyCancelled = CustomerBonusLog::withoutGlobalScopes()
            ->where('tenant_id', $order->tenant_id)
            ->where('order_id', $order->id)
            ->where('type', 'cancel')
            ->exists();

        if ($alreadyCancelled) {
            return null;
        }

        return DB::transaction(function () use ($order, $earnLog, $phone) {
            $bonus = CustomerBonus::withoutGlobalScopes()
                ->where('tenant_id', $order->tenant_id)
                ->where('customer_phone', $phone)
                ->lockForUpdate()
                ->first();

            if (! $bonus) {
                return null;
            }

            $bonusToRevert = (int) $earnLog->bonus_amount;
            $spendToRevert = (int) $earnLog->transaction_amount;

            $bonus->total_orders = max(0, $bonus->total_orders - 1);
            $bonus->total_spend = max(0, $bonus->total_spend - $spendToRevert);
            $bonus->total_bonus_earned = max(0, $bonus->total_bonus_earned - $bonusToRevert);
            $bonus->bonus_balance = max(0, $bonus->bonus_balance - $bonusToRevert);
            $bonus->save();

            $log = CustomerBonusLog::create([
                'tenant_id' => $order->tenant_id,
                'customer_bonus_id' => $bonus->id,
                'customer_phone' => $phone,
                'order_id' => $order->id,
                'order_code' => $order->code,
                'type' => 'cancel',
                'transaction_amount' => $spendToRevert,
                'bonus_percent' => $earnLog->bonus_percent,
                'bonus_amount' => -$bonusToRevert,
                'balance_after' => $bonus->bonus_balance,
                'notes' => "Pembatalan bonus transaksi #{$order->code}",
            ]);

            $order->updateQuietly(['bonus_amount' => 0]);

            Log::info("Customer bonus cancelled: phone={$phone}, bonus_reverted={$bonusToRevert}, order=#{$order->code}");

            return $log;
        });
    }

    /**
     * Claim / withdraw bonus
     */
    public function claimBonus(int $tenantId, int $customerBonusId, int $claimAmount, ?string $notes = null, ?int $userId = null): CustomerBonus
    {
        if ($claimAmount <= 0) {
            throw ValidationException::withMessages([
                'amount' => ['Nominal pencairan bonus harus lebih dari 0.'],
            ]);
        }

        return DB::transaction(function () use ($tenantId, $customerBonusId, $claimAmount, $notes, $userId) {
            $bonus = CustomerBonus::withoutGlobalScopes()
                ->where('tenant_id', $tenantId)
                ->where('id', $customerBonusId)
                ->lockForUpdate()
                ->firstOrFail();

            if ($bonus->bonus_balance < $claimAmount) {
                throw ValidationException::withMessages([
                    'amount' => ['Saldo bonus tidak mencukupi. Saldo saat ini: Rp ' . number_format($bonus->bonus_balance, 0, ',', '.')],
                ]);
            }

            $bonus->total_bonus_claimed += $claimAmount;
            $bonus->bonus_balance -= $claimAmount;
            $bonus->save();

            CustomerBonusLog::create([
                'tenant_id' => $tenantId,
                'customer_bonus_id' => $bonus->id,
                'customer_phone' => $bonus->customer_phone,
                'order_id' => null,
                'order_code' => null,
                'type' => 'claim',
                'transaction_amount' => $claimAmount,
                'bonus_percent' => 0,
                'bonus_amount' => -$claimAmount,
                'balance_after' => $bonus->bonus_balance,
                'notes' => $notes ?: 'Pencairan/klaim bonus tunai',
                'user_id' => $userId,
            ]);

            Log::info("Customer bonus claimed: phone={$bonus->customer_phone}, amount={$claimAmount}, remaining={$bonus->bonus_balance}");

            return $bonus;
        });
    }
}
