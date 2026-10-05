<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Menu;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderItemTopping;
use App\Models\Table;
use App\Models\Topping;
use App\Support\StoreOpeningHours;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    public function store(Request $request)
    {
        $tenantId = app()->has('tenant') ? app('tenant')->id : null;
        $tenant = app()->has('tenant') ? app('tenant') : null;
        if ($tenant && (! $tenant->is_store_open || ! StoreOpeningHours::wasOpenedDuringCurrentWindow(
            $tenant->opening_hours,
            $tenant->store_opened_at
        ))) {
            $message = StoreOpeningHours::isOpen($tenant->opening_hours)
                ? 'Toko belum dibuka oleh staf. Silakan tunggu kasir atau admin membuka toko.'
                : 'Toko sedang di luar jam operasional. Jam buka: '.($tenant->opening_hours ?: 'belum diatur').'.';

            return response()->json([
                'status' => false,
                'message' => $message,
            ], 422);
        }

        $request->validate([
            'table_code' => ['nullable', 'string'],
            'order_type' => ['nullable', 'string', 'in:dine_in,pickup,delivery'],
            'delivery_address' => ['required_if:order_type,delivery', 'nullable', 'string', 'max:1000'],
            'customer_name' => ['nullable', 'string', 'max:100'],
            'customer_phone' => ['nullable', 'string', 'max:20'],
            'payment_method' => ['nullable', 'string', 'in:qris,cash'],
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

        $order = DB::transaction(function () use ($request, $tableId, $orderType) {
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
                'payment_method' => $request->payment_method ?? 'qris',
                'total_amount' => 0,
            ]);

            $total = 0;

            foreach ($request->items as $itemData) {
                /** @var \App\Models\Menu $menu */
                $menu = Menu::findOrFail($itemData['menu_id']);
                $quantity = (int) $itemData['quantity'];

                $orderItem = OrderItem::create([
                    'order_id' => $order->id,
                    'menu_id' => $menu->id,
                    'menu_name' => $menu->name,
                    'price' => $menu->price,
                    'quantity' => $quantity,
                    'notes' => $itemData['notes'] ?? null,
                ]);

                $lineTotal = $menu->price * $quantity;

                $toppingIds = $itemData['topping_ids'] ?? [];
                if (count($toppingIds)) {
                    $toppings = Topping::whereIn('id', $toppingIds)->get();
                    foreach ($toppings as $topping) {
                        OrderItemTopping::create([
                            'order_item_id' => $orderItem->id,
                            'topping_id' => $topping->id,
                            'topping_name' => $topping->name,
                            'topping_price' => $topping->price,
                        ]);
                        $lineTotal += $topping->price;
                    }
                }

                $total += $lineTotal;
            }

            $order->update(['total_amount' => $total]);

            return $order;
        });

        return response()->json([
            'status' => true,
            'message' => 'success',
            'data' => [
                'code' => $order->code,
                'payment_method' => $order->payment_method,
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

        // Filter by status if provided
        if ($request->has('status')) {
            $query->where('status', $request->status);
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
                    'created_at' => $order->created_at->toIso8601String(),
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
                            'notes' => $item->notes,
                            'toppings' => $item->toppings->map(function (OrderItemTopping $topping) {
                                return [
                                    'topping_name' => $topping->topping_name,
                                    'topping_price' => $topping->topping_price,
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

        $order->status = $request->status;
        $order->save();

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

    /**
     * Get sales statistics for manager dashboard
     */
    public function salesStats()
    {
        $paidStatuses = ['PAID', 'PROCESSING', 'READY', 'SERVED'];

        // Get daily sales for the last 7 days
        $dailySales = [];
        for ($i = 6; $i >= 0; $i--) {
            $date = now()->subDays($i)->format('Y-m-d');
            $dayName = now()->subDays($i)->format('D');

            $total = Order::whereDate('created_at', $date)
                ->whereIn('status', $paidStatuses)
                ->sum('total_amount');

            $orderCount = Order::whereDate('created_at', $date)
                ->whereIn('status', $paidStatuses)
                ->count();

            $dailySales[] = [
                'date' => $date,
                'day' => $dayName,
                'total' => (int) $total,
                'orders' => $orderCount,
            ];
        }

        // Get total stats
        $totalRevenue = Order::whereIn('status', $paidStatuses)->sum('total_amount');
        $totalOrders = Order::whereIn('status', $paidStatuses)->count();
        $todayRevenue = Order::whereDate('created_at', now()->format('Y-m-d'))
            ->whereIn('status', $paidStatuses)
            ->sum('total_amount');
        $todayOrders = Order::whereDate('created_at', now()->format('Y-m-d'))
            ->whereIn('status', $paidStatuses)
            ->count();
        $monthRevenue = Order::whereYear('created_at', now()->year)
            ->whereMonth('created_at', now()->month)
            ->whereIn('status', $paidStatuses)
            ->sum('total_amount');
        $monthOrders = Order::whereYear('created_at', now()->year)
            ->whereMonth('created_at', now()->month)
            ->whereIn('status', $paidStatuses)
            ->count();
        $averageOrderValue = $totalOrders > 0 ? (int) round($totalRevenue / $totalOrders) : 0;

        // Top selling menus (last 30 days)
        $topMenus = OrderItem::selectRaw('menu_name, SUM(quantity) as total_qty, SUM(price * quantity) as total_sales')
            ->whereHas('order', function ($query) use ($paidStatuses) {
                $query->where('created_at', '>=', now()->subDays(30))
                    ->whereIn('status', $paidStatuses);
            })
            ->groupBy('menu_name')
            ->orderByDesc('total_qty')
            ->limit(5)
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
                'daily_sales' => $dailySales,
                'summary' => [
                    'total_revenue' => (int) $totalRevenue,
                    'total_orders' => $totalOrders,
                    'today_revenue' => (int) $todayRevenue,
                    'today_orders' => $todayOrders,
                    'month_revenue' => (int) $monthRevenue,
                    'month_orders' => $monthOrders,
                    'average_order_value' => $averageOrderValue,
                ],
                'top_menus' => $topMenus,
                'busy_days' => $busyDays,
                'busiest_day' => $busiestDay,
            ],
        ]);
    }
}
