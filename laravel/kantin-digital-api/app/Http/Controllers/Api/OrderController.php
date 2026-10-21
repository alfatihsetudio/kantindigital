<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderItemTopping;
use App\Models\Table;
use App\Models\Voucher;
use App\Support\StoreOpeningHours;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    private function releaseOrderVoucher(Order $order): void
    {
        Voucher::withoutGlobalScopes()
            ->where('order_id', $order->id)
            ->update([
                'status' => 'unused',
                'order_id' => null,
                'order_code' => null,
                'used_by_name' => null,
                'used_by_phone' => null,
                'used_at' => null,
                'is_reported' => false,
                'reported_at' => null,
            ]);
    }

    public function store(Request $request)
    {
        $tenantId = app()->has('tenant') ? app('tenant')->id : null;
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if ($tenant && ! $tenant->is_store_open) {
            $hoursText = $tenant->opening_hours ?: 'belum diatur';
            $qrisSetting = $tenant
                ? \App\Models\QrisSetting::withoutGlobalScopes()->where('tenant_id', $tenant->id)->first()
                : null;
            if (! $qrisSetting) {
                $qrisSetting = \App\Models\QrisSetting::withoutGlobalScopes()->first();
            }
            $whatsappNumber = $qrisSetting?->whatsapp_number ?? data_get($tenant, 'whatsapp') ?? data_get($tenant, 'phone');
            $contactInfo = $whatsappNumber ? ' Layanan Konsumen: '.$whatsappNumber.'.' : '';

            if (StoreOpeningHours::isOpen($tenant->opening_hours)) {
                $message = 'Mohon Maaf karena suatu hal, saat ini kami sedang Tutup. Jam Operasional: '.$hoursText.'.'.$contactInfo.' Silakan tunggu toko buka kembali.';
            } elseif (StoreOpeningHours::isTodayClosed($tenant->opening_hours)) {
                $message = 'Hari ini toko kami sedang libur operasional. Jadwal buka: '.$hoursText.'.';
            } else {
                $message = 'Toko sedang di luar jam operasional. Jam buka: '.$hoursText.'.';
            }

            return response()->json([
                'status' => false,
                'message' => $message,
            ], 422);
        }

        $request->validate([
            'table_code' => ['nullable', 'string'],
            'order_type' => ['nullable', 'string', 'in:dine_in,pickup,delivery'],
            'delivery_address' => ['required_if:order_type,delivery', 'nullable', 'string', 'max:2000'],
            'customer_name' => ['nullable', 'string', 'max:100'],
            'customer_phone' => ['nullable', 'string', 'max:30'],
            'payment_method' => ['nullable', 'string', 'in:qris,cash'],
            'voucher_code' => ['nullable', 'string', 'max:100'],
            'items' => ['required', 'array', 'min:1', 'max:20'],
            'items.*.menu_id' => [
                'required',
                'integer',
                Rule::exists('menus', 'id')->where('tenant_id', $tenantId),
            ],
            'items.*.quantity' => ['required', 'integer', 'min:1', 'max:20'],
            'items.*.topping_ids' => ['sometimes', 'array', 'max:5'],
            'items.*.topping_ids.*' => [
                'integer',
                'distinct',
                Rule::exists('toppings', 'id')->where('tenant_id', $tenantId),
            ],
            'items.*.toppings' => ['sometimes', 'array', 'max:5'],
            'items.*.toppings.*.topping_id' => [
                'required',
                'integer',
                'distinct',
                Rule::exists('toppings', 'id')->where('tenant_id', $tenantId),
            ],
            'items.*.toppings.*.quantity' => ['required', 'integer', 'min:1', 'max:20'],
            'items.*.notes' => ['nullable', 'string', 'max:500'],
        ]);

        $unavailableMenus = Menu::whereIn(
            'id',
            collect($request->input('items'))->pluck('menu_id')->unique()
        )->where('is_available', false)->pluck('name');
        if ($unavailableMenus->isNotEmpty()) {
            return response()->json([
                'status' => false,
                'message' => 'Menu tidak tersedia: '.$unavailableMenus->implode(', '),
            ], 422);
        }

        // table_code opsional: pesanan online bisa tanpa meja
        $tableId = null;
        if ($request->filled('table_code')) {
            $table = Table::where('code', $request->table_code)->first();
            if (! $table) {
                return response()->json([
                    'status' => false,
                    'message' => 'Meja tidak ditemukan',
                ], 404);
            }
            $tableId = $table->id;
        }
        $orderType = $request->input('order_type')
            ?? ($tableId === null ? 'pickup' : 'dine_in');
        if ($orderType === 'dine_in' && $tableId === null) {
            return response()->json([
                'status' => false,
                'message' => 'Meja wajib dipilih untuk pesanan makan di tempat',
            ], 422);
        }
        if ($orderType !== 'dine_in') {
            $tableId = null;
        }

        $paymentMethod = $request->payment_method ?? 'qris';

        $order = DB::transaction(function () use ($request, $tableId, $orderType, $tenant, $paymentMethod) {
            $order = Order::create([
                'code' => strtoupper(Str::random(8)),
                'customer_name' => $request->customer_name,
                'customer_phone' => $request->customer_phone,
                'table_id' => $tableId,
                'order_type' => $orderType,
                'delivery_address' => $orderType === 'delivery'
                    ? $request->delivery_address
                    : null,
                'status' => 'UNPAID',
                'payment_method' => $paymentMethod,
                'total_amount' => 0,
                'discount_amount' => 0,
                'voucher_code' => null,
                'voucher_discount_amount' => 0,
            ]);

            $voucherPromoMode = data_get($tenant, 'voucher_promo_mode', 'both') ?: 'both';
            $voucher = null;

            if ($request->filled('voucher_code')) {
                $rawVoucherCode = strtoupper(trim((string) $request->input('voucher_code')));
                if ($rawVoucherCode !== '') {
                    if ($voucherPromoMode === 'promo_only') {
                        throw \Illuminate\Validation\ValidationException::withMessages([
                            'voucher_code' => ['Penggunaan kode voucher sedang dinonaktifkan (hanya berlaku diskon promo umum).'],
                        ]);
                    }

                    $voucher = Voucher::whereRaw('UPPER(code) = ?', [$rawVoucherCode])
                        ->lockForUpdate()
                        ->first();

                    if (! $voucher) {
                        throw \Illuminate\Validation\ValidationException::withMessages([
                            'voucher_code' => ['Kode voucher tidak ditemukan atau tidak terdaftar.'],
                        ]);
                    }

                    if ($voucher->status === 'used') {
                        throw \Illuminate\Validation\ValidationException::withMessages([
                            'voucher_code' => ['Kode voucher ini sudah pernah digunakan.'],
                        ]);
                    }
                }
            }

            $total = 0;
            $totalDiscount = 0;
            $promoPercent = min(100, max(0, (int) data_get($tenant, 'promo_discount_percent', 0)));
            if ($voucherPromoMode === 'voucher_only' || ($voucherPromoMode === 'single' && $voucher !== null)) {
                $promoPercent = 0;
            }
            $promoScope = data_get($tenant, 'promo_scope', 'all') ?: 'all';
            $promoMenuIds = collect(data_get($tenant, 'promo_menu_ids', []))
                ->map(fn ($id) => (int) $id)
                ->all();
            $promoPaymentMethods = collect(data_get($tenant, 'promo_payment_methods') ?: ['qris'])
                ->map(fn ($method) => strtolower(trim((string) $method)))
                ->filter(fn ($method) => in_array($method, ['qris', 'cash'], true))
                ->values()
                ->all();
            $promoAppliesToPayment = in_array($paymentMethod, $promoPaymentMethods, true);

            foreach ($request->items as $itemData) {
                /** @var \App\Models\Menu $menu */
                $menu = Menu::with('toppings')->findOrFail($itemData['menu_id']);
                $quantity = (int) $itemData['quantity'];
                $note = trim((string) ($itemData['notes'] ?? ''));
                $noteOptions = $menu->note_options ?? [];
                if ($note !== '' && $noteOptions !== [] && ! in_array($note, $noteOptions, true)) {
                    throw \Illuminate\Validation\ValidationException::withMessages([
                        'items' => ["Pilihan catatan untuk menu {$menu->name} tidak valid."],
                    ]);
                }
                $lineDiscount = $promoAppliesToPayment
                    && $promoPercent > 0
                    && ($promoScope !== 'selected' || in_array($menu->id, $promoMenuIds, true))
                    ? intdiv(($menu->price * $quantity * $promoPercent) + 50, 100)
                    : 0;

                $orderItem = OrderItem::create([
                    'order_id' => $order->id,
                    'menu_id' => $menu->id,
                    'menu_name' => $menu->name,
                    'price' => $menu->price,
                    'quantity' => $quantity,
                    'notes' => $note !== '' ? $note : null,
                    'discount_amount' => $lineDiscount,
                ]);

                $lineTotal = $menu->price * $quantity;

                $toppingSelections = $itemData['toppings'] ?? collect(
                    $itemData['topping_ids'] ?? []
                )->map(fn ($id) => ['topping_id' => $id, 'quantity' => 1])->all();

                foreach ($toppingSelections as $selection) {
                    $toppingId = (int) ($selection['topping_id'] ?? 0);
                    $topping = $menu->toppings->firstWhere('id', $toppingId);
                    if (! $topping) {
                        throw \Illuminate\Validation\ValidationException::withMessages([
                            'items' => ["Toping {$toppingId} tidak tersedia untuk menu {$menu->name}."],
                        ]);
                    }

                    $toppingQuantity = (int) ($selection['quantity'] ?? 1);
                    $maxQuantity = (int) $topping->pivot->max;
                    if ($maxQuantity > 0 && $toppingQuantity > $maxQuantity) {
                        throw \Illuminate\Validation\ValidationException::withMessages([
                            'items' => ["Jumlah toping {$topping->name} melebihi batas menu."],
                        ]);
                    }

                    OrderItemTopping::create([
                        'order_item_id' => $orderItem->id,
                        'topping_id' => $topping->id,
                        'topping_name' => $topping->name,
                        'topping_price' => $topping->price,
                        'quantity' => $toppingQuantity,
                    ]);
                    $lineTotal += $topping->price * $toppingQuantity;
                }

                $total += $lineTotal - $lineDiscount;
                $totalDiscount += $lineDiscount;
            }

            $voucherCode = null;
            $voucherDiscount = 0;

            if ($voucher !== null) {
                $voucherDiscount = min($total, max(0, (int) $voucher->amount));
                $total = max(0, $total - $voucherDiscount);
                $totalDiscount += $voucherDiscount;
                $voucherCode = $voucher->code;

                $voucher->update([
                    'status' => 'used',
                    'order_id' => $order->id,
                    'order_code' => $order->code,
                    'used_by_name' => $order->customer_name,
                    'used_by_phone' => $order->customer_phone,
                    'used_at' => now(),
                ]);
            }

            // Hitung diskon potongan pengiriman berdasarkan total kuantitas seluruh item
            $deliveryDiscount = 0;
            $totalQuantity = collect($request->items)->sum(fn ($i) => (int) ($i['quantity'] ?? 0));
            $tiers = collect(data_get($tenant, 'delivery_discount_tiers', []))
                ->filter(fn ($t) => is_array($t) && ! empty($t['min_qty']) && ! empty($t['discount_amount']))
                ->sortByDesc(fn ($t) => (int) $t['min_qty']);

            foreach ($tiers as $tier) {
                if ($totalQuantity >= (int) $tier['min_qty']) {
                    $deliveryDiscount = (int) $tier['discount_amount'];
                    break;
                }
            }

            if ($deliveryDiscount > 0) {
                $deliveryDiscount = min($total, $deliveryDiscount);
                $total = max(0, $total - $deliveryDiscount);
                $totalDiscount += $deliveryDiscount;
            }

            $order->update([
                'total_amount' => $total,
                'discount_amount' => $totalDiscount,
                'voucher_code' => $voucherCode,
                'voucher_discount_amount' => $voucherDiscount,
                'delivery_discount_amount' => $deliveryDiscount,
            ]);

            return $order;
        });

        return response()->json([
            'status' => true,
            'message' => 'success',
            'data' => [
                'code' => $order->code,
                'payment_method' => $order->payment_method,
                'voucher_code' => $order->voucher_code,
                'voucher_discount_amount' => (int) ($order->voucher_discount_amount ?? 0),
                'delivery_discount_amount' => (int) ($order->delivery_discount_amount ?? 0),
            ],
        ], 201);
    }

    public function show(string $code)
    {
        $order = Order::with(['table', 'items.toppings'])
            ->where('code', $code)
            ->firstOrFail();

        $qrisSetting = $order->tenant_id
            ? \App\Models\QrisSetting::withoutGlobalScopes()->where('tenant_id', $order->tenant_id)->first()
            : \App\Models\QrisSetting::first();

        if (! $qrisSetting) {
            $qrisSetting = \App\Models\QrisSetting::withoutGlobalScopes()->where('tenant_id', 1)->first()
                ?? \App\Models\QrisSetting::withoutGlobalScopes()->first();
        }

        $merchantName = $qrisSetting->merchant_name ?? env('QRIS_MERCHANT_NAME', 'Say Coffee');
        $merchantCity = $qrisSetting->merchant_city ?? env('QRIS_MERCHANT_CITY', 'Kab. Serang');
        $basePayload = (! empty($qrisSetting->base_payload))
            ? $qrisSetting->base_payload
            : env('QRIS_BASE_PAYLOAD', '00020101021126570011ID.DANA.WWW011893600915303557205402090355720540303UMI51440014ID.CO.QRIS.WWW0215ID10266058542500303UMI5204581253033605802ID5910Say Coffee6011Kab. Serang6105421176304AB0C');

        $qrisService = app(\App\Services\QrisDynamicService::class);
        $qrisPayload = $qrisService->generatePayload($basePayload, (int) $order->total_amount);

        $data = [
            'id' => $order->id,
            'code' => $order->code,
            'customer_name' => $order->customer_name,
            'customer_phone' => $order->customer_phone,
            'order_type' => $order->order_type,
            'delivery_address' => $order->delivery_address,
            'status' => $order->status,
            'payment_method' => $order->payment_method ?? 'qris',
            'total_amount' => $order->total_amount,
            'discount_amount' => $order->discount_amount,
            'voucher_code' => $order->voucher_code,
            'voucher_discount_amount' => (int) ($order->voucher_discount_amount ?? 0),
            'delivery_discount_amount' => (int) ($order->delivery_discount_amount ?? 0),
            'qris' => [
                'merchant_name' => $merchantName,
                'merchant_city' => $merchantCity,
                'whatsapp_number' => $qrisSetting->whatsapp_number ?? '087771262100',
                'payload' => $qrisPayload,
                'amount' => (int) $order->total_amount,
            ],
            'table' => $order->table ? [
                'id' => $order->table->id,
                'code' => $order->table->code,
                'name' => $order->table->name,
            ] : null,
            'items' => $order->items->map(function (OrderItem $item) {
                return [
                    'id' => $item->id,
                    'menu_id' => $item->menu_id,
                    'menu_name' => $item->menu_name,
                    'price' => $item->price,
                    'quantity' => $item->quantity,
                    'notes' => $item->notes,
                    'toppings' => $item->toppings->map(function (OrderItemTopping $topping) {
                        return [
                            'id' => $topping->id,
                            'topping_id' => $topping->topping_id,
                            'topping_name' => $topping->topping_name,
                            'topping_price' => $topping->topping_price,
                            'quantity' => $topping->quantity,
                        ];
                    })->values(),
                ];
            })->values(),
            'payment' => null,
        ];

        return response()->json([
            'status' => true,
            'message' => 'success',
            'data' => $data,
        ], 200);
    }

    public function cancelCustomerOrder(string $code)
    {
        $order = Order::where('code', $code)->first();
        if (! $order) {
            return response()->json([
                'status' => false,
                'message' => 'Pesanan tidak ditemukan.',
            ], 404);
        }

        if ($order->status === 'CANCELLED') {
            return response()->json([
                'status' => true,
                'message' => 'Pesanan sudah dibatalkan.',
                'data' => [
                    'id' => $order->id,
                    'code' => $order->code,
                    'status' => $order->status,
                ],
            ], 200);
        }

        if ($order->status !== 'UNPAID') {
            return response()->json([
                'status' => false,
                'message' => 'Pesanan tidak dapat dibatalkan karena sudah dibayar atau sedang diproses.',
            ], 422);
        }

        $order->status = 'CANCELLED';
        $order->save();
        $this->releaseOrderVoucher($order);

        return response()->json([
            'status' => true,
            'message' => 'Pesanan berhasil dibatalkan.',
            'data' => [
                'id' => $order->id,
                'code' => $order->code,
                'status' => $order->status,
            ],
        ], 200);
    }

    public function indexForKitchen()
    {
        $orders = Order::with('table')
            ->whereIn('status', ['PAID', 'PROCESSING'])
            ->orderBy('created_at')
            ->get();

        return response()->json([
            'status' => true,
            'message' => 'success',
            'data' => $orders->map(function (Order $order) {
                return [
                    'id' => $order->id,
                    'code' => $order->code,
                    'status' => $order->status,
                    'order_type' => $order->order_type,
                    'delivery_address' => $order->delivery_address,
                    'table' => $order->table ? [
                        'id' => $order->table->id,
                        'code' => $order->table->code,
                        'name' => $order->table->name,
                    ] : null,
                ];
            }),
        ], 200);
    }

    public function indexForCashier(Request $request)
    {
        $query = Order::with(['table', 'items.toppings']);

        // Filter by status if provided (pesanan palsu/batal tidak ditampilkan untuk hari kemarin)
        if ($request->filled('status')) {
            $query->where('status', $request->status);
            if ($request->status === 'CANCELLED') {
                $query->whereDate('created_at', '>=', now()->startOfDay());
            } elseif ($request->status === 'SERVED') {
                // Tampilkan pesanan yang hari ini atau yang belum disetor (shift berjalan)
                $query->where(function ($q) {
                    $q->whereDate('created_at', '>=', now()->startOfDay())
                      ->orWhereNull('cashier_shift_report_id');
                });
            }
        } else {
            $query->where(function ($q) {
                $q->where('status', '!=', 'CANCELLED')
                  ->orWhereDate('created_at', '>=', now()->startOfDay());
            });
        }

        $orders = $query->orderByDesc('created_at')->limit(100)->get();

        return response()->json([
            'status' => true,
            'message' => 'success',
            'data' => $orders->map(function (Order $order) {
                return [
                    'id' => $order->id,
                    'code' => $order->code,
                    'customer_name' => $order->customer_name,
                    'customer_phone' => $order->customer_phone,
                    'status' => $order->status,
                    'payment_method' => $order->payment_method ?? 'qris',
                    'total_amount' => $order->total_amount,
                    'discount_amount' => $order->discount_amount,
                    'voucher_code' => $order->voucher_code,
                    'voucher_discount_amount' => (int) ($order->voucher_discount_amount ?? 0),
                    'delivery_discount_amount' => (int) ($order->delivery_discount_amount ?? 0),
                    'created_at' => $order->created_at->toIso8601String(),
                    'cashier_shift_report_id' => $order->cashier_shift_report_id,
                    'order_type' => $order->order_type,
                    'delivery_address' => $order->delivery_address,
                    'table' => $order->table ? [
                        'id' => $order->table->id,
                        'code' => $order->table->code,
                        'name' => $order->table->name,
                    ] : null,
                    'items' => $order->items->map(function (OrderItem $item) {
                        return [
                            'menu_name' => $item->menu_name,
                            'quantity' => $item->quantity,
                            'price' => $item->price,
                            'discount_amount' => $item->discount_amount,
                            'notes' => $item->notes,
                            'toppings' => $item->toppings->map(function (OrderItemTopping $topping) {
                                return [
                                    'topping_name' => $topping->topping_name,
                                    'topping_price' => $topping->topping_price,
                                    'quantity' => $topping->quantity,
                                ];
                            })->values(),
                        ];
                    })->values(),
                ];
            }),
        ], 200);
    }

    public function updateStatus(Request $request, Order $order)
    {
        $request->validate([
            'status' => ['required', 'string', 'in:UNPAID,PAID,PROCESSING,READY,SERVED,CANCELLED'],
        ]);

        $prevStatus = $order->status;
        $order->status = $request->status;

        // Jika pesanan sebelumnya CANCELLED dan diaktifkan kembali ("Jadi Pesan" hari ini)
        if ($prevStatus === 'CANCELLED' && in_array($request->status, ['UNPAID', 'PROCESSING', 'PAID'])) {
            if ($request->boolean('restore_today', true) || $order->created_at->lt(now()->startOfDay())) {
                $order->created_at = now();
            }
        }

        $order->save();

        if ($order->status === 'CANCELLED') {
            $this->releaseOrderVoucher($order);
        }

        return response()->json([
            'status' => true,
            'message' => 'success',
            'data' => [
                'id' => $order->id,
                'code' => $order->code,
                'status' => $order->status,
            ],
        ], 200);
    }

    public function destroy(Order $order)
    {
        DB::transaction(function () use ($order) {
            $this->releaseOrderVoucher($order);
            foreach ($order->items as $item) {
                $item->toppings()->delete();
            }
            $order->items()->delete();
            $order->delete();
        });

        return response()->json([
            'status' => true,
            'message' => 'Transaksi berhasil dihapus.',
        ], 200);
    }

    public function bulkDestroy(Request $request)
    {
        $request->validate([
            'status' => ['nullable', 'string', 'in:UNPAID,CANCELLED,PAID,PROCESSING,READY,SERVED'],
            'order_ids' => ['nullable', 'array'],
            'order_ids.*' => ['integer'],
        ]);

        $query = Order::query();

        if ($request->filled('order_ids') && is_array($request->order_ids)) {
            $query->whereIn('id', $request->order_ids);
        } elseif ($request->filled('status')) {
            $query->where('status', $request->status);
        } else {
            $query->where('status', 'CANCELLED');
        }

        $orders = $query->with('items')->get();
        $deletedCount = $orders->count();

        DB::transaction(function () use ($orders) {
            foreach ($orders as $order) {
                $this->releaseOrderVoucher($order);
                foreach ($order->items as $item) {
                    $item->toppings()->delete();
                }
                $order->items()->delete();
                $order->delete();
            }
        });

        return response()->json([
            'status' => true,
            'message' => "$deletedCount transaksi berhasil dihapus.",
            'data' => [
                'deleted_count' => $deletedCount,
            ],
        ], 200);
    }

    /**
     * Get sales statistics for manager dashboard
    /**
     * Get sales statistics for manager dashboard
     * Supports period filters (today, yesterday, 7days, 30days, this_month, custom)
     * and cup count calculations.
     */
    public function salesStats(Request $request)
    {
        $paidStatuses = ['PAID', 'PROCESSING', 'READY', 'SERVED'];

        $period = $request->get('period', '7days');
        $now = now();

        switch ($period) {
            case 'today':
                $startDate = $now->copy()->startOfDay();
                $endDate = $now->copy()->endOfDay();
                break;
            case 'yesterday':
                $startDate = $now->copy()->subDay()->startOfDay();
                $endDate = $now->copy()->subDay()->endOfDay();
                break;
            case '30days':
                $startDate = $now->copy()->subDays(29)->startOfDay();
                $endDate = $now->copy()->endOfDay();
                break;
            case 'this_month':
                $startDate = $now->copy()->startOfMonth();
                $endDate = $now->copy()->endOfMonth();
                break;
            case 'custom':
                if ($request->filled('start_date') && $request->filled('end_date')) {
                    $startDate = \Illuminate\Support\Carbon::parse($request->get('start_date'))->startOfDay();
                    $endDate = \Illuminate\Support\Carbon::parse($request->get('end_date'))->endOfDay();
                } else {
                    $startDate = $now->copy()->subDays(6)->startOfDay();
                    $endDate = $now->copy()->endOfDay();
                }
                break;
            case '7days':
            default:
                $period = '7days';
                $startDate = $now->copy()->subDays(6)->startOfDay();
                $endDate = $now->copy()->endOfDay();
                break;
        }

        // Daily breakdown between $startDate and $endDate
        $diffInDays = $startDate->diffInDays($endDate);
        if ($diffInDays > 60) {
            $diffInDays = 60; // Max 60 days
        }

        $dayNamesShort = [
            0 => 'Min',
            1 => 'Sen',
            2 => 'Sel',
            3 => 'Rab',
            4 => 'Kam',
            5 => 'Jum',
            6 => 'Sab',
        ];

        // Fetch orders in period with items to calculate total amount & cup quantities
        $periodOrdersList = Order::whereIn('status', $paidStatuses)
            ->whereBetween('created_at', [$startDate, $endDate])
            ->with(['items:id,order_id,quantity'])
            ->get(['id', 'total_amount', 'created_at']);

        $groupedByDate = $periodOrdersList->groupBy(function ($order) {
            return $order->created_at->format('Y-m-d');
        });

        $dailySales = [];
        for ($i = 0; $i <= $diffInDays; $i++) {
            $currentDate = $startDate->copy()->addDays($i);
            $dateStr = $currentDate->format('Y-m-d');
            $dayOfWeek = $currentDate->dayOfWeek;
            $dayName = $dayNamesShort[$dayOfWeek] ?? $currentDate->format('D');

            $ordersOnDate = $groupedByDate->get($dateStr, collect());
            $dailySales[] = [
                'date' => $dateStr,
                'day' => $dayName,
                'total' => (int) $ordersOnDate->sum('total_amount'),
                'orders' => $ordersOnDate->count(),
                'cups' => (int) $ordersOnDate->sum(fn($o) => $o->items->sum('quantity')),
            ];
        }

        // Period Summary
        $periodRevenue = (int) $periodOrdersList->sum('total_amount');
        $periodOrders = $periodOrdersList->count();
        $periodCups = (int) $periodOrdersList->sum(fn($o) => $o->items->sum('quantity'));

        // Today metrics
        $todayStr = now()->format('Y-m-d');
        $todayOrdersList = Order::whereIn('status', $paidStatuses)
            ->whereDate('created_at', $todayStr)
            ->with(['items:id,order_id,quantity'])
            ->get(['id', 'total_amount', 'created_at']);
        $todayRevenue = (int) $todayOrdersList->sum('total_amount');
        $todayOrders = $todayOrdersList->count();
        $todayCups = (int) $todayOrdersList->sum(fn($o) => $o->items->sum('quantity'));

        // Month metrics
        $monthOrdersList = Order::whereIn('status', $paidStatuses)
            ->whereYear('created_at', now()->year)
            ->whereMonth('created_at', now()->month)
            ->with(['items:id,order_id,quantity'])
            ->get(['id', 'total_amount', 'created_at']);
        $monthRevenue = (int) $monthOrdersList->sum('total_amount');
        $monthOrders = $monthOrdersList->count();
        $monthCups = (int) $monthOrdersList->sum(fn($o) => $o->items->sum('quantity'));

        // All time stats
        $totalRevenue = (int) Order::whereIn('status', $paidStatuses)->sum('total_amount');
        $totalOrders = (int) Order::whereIn('status', $paidStatuses)->count();
        $totalCups = (int) OrderItem::whereHas('order', function ($q) use ($paidStatuses) {
            $q->whereIn('status', $paidStatuses);
        })->sum('quantity');

        $averageOrderValue = $periodOrders > 0 ? (int) round($periodRevenue / $periodOrders) : 0;
        $averageCupsPerOrder = $periodOrders > 0 ? round($periodCups / $periodOrders, 1) : 0.0;

        // Top selling menus in selected period
        $topMenus = OrderItem::selectRaw(
            'menu_name, SUM(quantity) as total_qty, SUM(price * quantity - discount_amount) as total_sales'
        )
            ->whereHas('order', function ($query) use ($paidStatuses, $startDate, $endDate) {
                $query->whereBetween('created_at', [$startDate, $endDate])
                    ->whereIn('status', $paidStatuses);
            })
            ->groupBy('menu_name')
            ->orderByDesc('total_qty')
            ->limit(10)
            ->get();

        $topMenusTotalQty = (int) $topMenus->sum('total_qty');
        $topMenus = $topMenus->map(function ($menu) use ($topMenusTotalQty) {
            $qty = (int) $menu->total_qty;

            return [
                'menu_name' => $menu->menu_name,
                'total_qty' => $qty,
                'total_sales' => (int) $menu->total_sales,
                'sales_share' => $topMenusTotalQty > 0 ? round(($qty / $topMenusTotalQty) * 100, 1) : 0,
            ];
        })->values();

        $dayNames = [
            1 => 'Senin',
            2 => 'Selasa',
            3 => 'Rabu',
            4 => 'Kamis',
            5 => 'Jumat',
            6 => 'Sabtu',
            7 => 'Minggu',
        ];
        $busyDays = collect($dayNames)->map(function ($dayName, $isoDay) use ($paidStatuses) {
            $orders = Order::whereIn('status', $paidStatuses)
                ->whereRaw('WEEKDAY(created_at) = ?', [$isoDay - 1]);

            return [
                'day' => $dayName,
                'orders' => (clone $orders)->count(),
                'revenue' => (int) (clone $orders)->sum('total_amount'),
            ];
        })->sortByDesc('orders')->values();

        $busiestDay = $busyDays->first();

        return response()->json([
            'status' => true,
            'data' => [
                'period' => $period,
                'start_date' => $startDate->format('Y-m-d'),
                'end_date' => $endDate->format('Y-m-d'),
                'daily_sales' => $dailySales,
                'summary' => [
                    'period_revenue' => (int) $periodRevenue,
                    'period_orders' => (int) $periodOrders,
                    'period_cups' => (int) $periodCups,
                    'today_revenue' => (int) $todayRevenue,
                    'today_orders' => (int) $todayOrders,
                    'today_cups' => (int) $todayCups,
                    'month_revenue' => (int) $monthRevenue,
                    'month_orders' => (int) $monthOrders,
                    'month_cups' => (int) $monthCups,
                    'total_revenue' => (int) $totalRevenue,
                    'total_orders' => (int) $totalOrders,
                    'total_cups' => (int) $totalCups,
                    'average_order_value' => (int) $averageOrderValue,
                    'average_cups_per_order' => (float) $averageCupsPerOrder,
                ],
                'top_menus' => $topMenus,
                'busy_days' => $busyDays,
                'busiest_day' => $busiestDay,
            ],
        ]);
    }
}
