<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CashierShiftReportController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\CustomerBonusController;
use App\Http\Controllers\Api\ExpenseController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\QrisSettingController;
use App\Http\Controllers\Api\RegisterStoreController;
use App\Http\Controllers\Api\StockController;
use App\Http\Controllers\Api\SuperAdminController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\TenantController;
use App\Http\Controllers\Api\ToppingController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\VoucherController;
use Illuminate\Support\Facades\Route;

// Public (customer & self-service registration)
Route::get('/app-manifest.json', [\App\Http\Controllers\Web\MetaController::class, 'manifest']);
Route::get('/manifest.json', [\App\Http\Controllers\Web\MetaController::class, 'manifest']);
Route::get('/manifest.webmanifest', [\App\Http\Controllers\Web\MetaController::class, 'manifest']);
Route::get('/tenant/info', [TenantController::class, 'info']); // info tenant dari subdomain
Route::get('/menus', [MenuController::class, 'index']);
Route::get('/menus/{menu}/toppings', [ToppingController::class, 'forMenu']);
Route::get('/tables', [TableController::class, 'index']);
Route::get('/toppings', [ToppingController::class, 'index']);
Route::get('/categories', [CategoryController::class, 'index']);
Route::get('/customer-bonus/check', [CustomerBonusController::class, 'check'])->middleware('throttle:public-orders');
Route::post('/customer-bonus/check', [CustomerBonusController::class, 'check'])->middleware('throttle:public-orders');
Route::post('/vouchers/check', [VoucherController::class, 'check'])->middleware('throttle:public-orders');
Route::get('/vouchers/check', [VoucherController::class, 'check'])->middleware('throttle:public-orders');
Route::post('/orders', [OrderController::class, 'store'])->middleware('throttle:public-orders');
Route::get('/orders/{code}', [OrderController::class, 'show']);
Route::post('/orders/{code}/cancel', [OrderController::class, 'cancelCustomerOrder'])->middleware('throttle:public-orders');
Route::post('/login', [AuthController::class, 'login']);
Route::get('/check-subdomain', [RegisterStoreController::class, 'checkSubdomain']);
Route::post('/register-store', [RegisterStoreController::class, 'registerStore']);
Route::get('/register-store/status/{invoiceCode}', [RegisterStoreController::class, 'checkStatus']);
Route::post('/register-store/simulate-paid/{invoiceCode}', [RegisterStoreController::class, 'simulatePaid']);
Route::get('/showcase-stores', [TenantController::class, 'showcaseStores']);
Route::get('/public/showcase-stores', [TenantController::class, 'showcaseStores']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::post('/change-password', [AuthController::class, 'changePassword']);
    Route::post('/update-profile', [AuthController::class, 'updateProfile']);

    Route::middleware('password.changed')->group(function () {
        Route::post('/tenant/update', [TenantController::class, 'update'])
            ->middleware('role:admin');
        Route::post('/tenant/voucher-promo-mode', [TenantController::class, 'updateVoucherPromoMode'])
            ->middleware('role:admin');
        Route::post('/tenant/store-status', [TenantController::class, 'updateStoreStatus'])
            ->middleware('role:admin,cashier');
        Route::post('/tenant/opening-hours', [TenantController::class, 'updateOpeningHours'])
            ->middleware('role:admin,cashier');

        Route::middleware('role:admin')->group(function () {
            Route::apiResource('menus', MenuController::class)->except(['index']);
            Route::post('/menus/{id}', [MenuController::class, 'update']);
            Route::apiResource('categories', CategoryController::class)->except(['index']);
            Route::post('/categories/{id}/toggle', [CategoryController::class, 'toggle']);
            Route::apiResource('tables', TableController::class)->except(['index']);
            Route::apiResource('toppings', ToppingController::class)->except(['index']);
            Route::post('/users', [UserController::class, 'store']);
            Route::put('/users/{id}', [UserController::class, 'update']);
            Route::patch('/users/{id}', [UserController::class, 'update']);
            Route::delete('/users/{id}', [UserController::class, 'destroy']);

            Route::get('/qris-setting', [QrisSettingController::class, 'show']);
            Route::post('/qris-setting', [QrisSettingController::class, 'update']);
            Route::put('/qris-setting', [QrisSettingController::class, 'update']);

            Route::delete('/orders/{order}', [OrderController::class, 'destroy']);
            Route::post('/orders/bulk-delete', [OrderController::class, 'bulkDestroy']);

            Route::post('/vouchers/import', [VoucherController::class, 'import']);
            Route::delete('/vouchers/{voucher}', [VoucherController::class, 'destroy']);
            Route::post('/vouchers/bulk-delete', [VoucherController::class, 'bulkDestroy']);
        });

        Route::get('/vouchers', [VoucherController::class, 'index'])
            ->middleware('role:admin,manager');
        Route::post('/vouchers/mark-reported', [VoucherController::class, 'markReported'])
            ->middleware('role:admin,manager');
        Route::get('/users', [UserController::class, 'index'])
            ->middleware('role:admin,manager');
        Route::get('/kitchen/orders', [OrderController::class, 'indexForKitchen'])
            ->middleware('role:admin,operations');
        Route::get('/cashier/orders', [OrderController::class, 'indexForCashier'])
            ->middleware('role:admin,cashier,operations');
        Route::post('/orders/{order}/status', [OrderController::class, 'updateStatus'])
            ->middleware('role:admin,cashier,operations');
        Route::get('/manager/stats', [OrderController::class, 'salesStats'])
            ->middleware('role:admin,manager');

        // Laporan Penjualan Waktu Buka Berjalan & ACC Uang Kasir
        Route::middleware('role:admin,cashier,manager')->group(function () {
            Route::get('/cashier/shift/current', [CashierShiftReportController::class, 'currentShift']);
            Route::post('/cashier/shift/submit', [CashierShiftReportController::class, 'submitReport']);
            Route::get('/cashier/shift/reports', [CashierShiftReportController::class, 'index']);
        });

        Route::middleware('role:admin,manager')->group(function () {
            Route::post('/cashier/shift/reports/{id}/approve', [CashierShiftReportController::class, 'approve']);
            Route::post('/cashier/shift/reports/{id}/reject', [CashierShiftReportController::class, 'reject']);
        });

        // Catatan Stok & Stock Opname (Buka Toko & Tutup Usaha)
        Route::middleware('role:admin,cashier,operations,manager')->group(function () {
            Route::get('/stock-items', [StockController::class, 'items']);
            Route::post('/stock-items', [StockController::class, 'storeItem']);
            Route::put('/stock-items/{id}', [StockController::class, 'updateItem']);
            Route::delete('/stock-items/{id}', [StockController::class, 'destroyItem']);

            Route::get('/stock-checks/latest-closing', [StockController::class, 'latestClosing']);
            Route::get('/stock-checks', [StockController::class, 'indexChecks']);
            Route::get('/stock-checks/{id}', [StockController::class, 'showCheck']);
            Route::post('/stock-checks', [StockController::class, 'storeCheck']);
        });

        // Daftar Belanja & Pengeluaran (input kasir, dilihat admin/owner & manajer)
        Route::middleware('role:admin,cashier,operations,manager')->group(function () {
            Route::get('/expenses', [ExpenseController::class, 'index']);
        });

        Route::middleware('role:admin,cashier,operations')->group(function () {
            Route::post('/expenses', [ExpenseController::class, 'store']);
            Route::put('/expenses/{id}', [ExpenseController::class, 'update']);
            Route::patch('/expenses/{id}', [ExpenseController::class, 'update']);
            Route::delete('/expenses/{id}', [ExpenseController::class, 'destroy']);
        });

        // Program Bonus / Loyalty Pelanggan (Admin, Kasir, Manajer)
        Route::middleware('role:admin,cashier,manager')->group(function () {
            Route::get('/customer-bonuses', [CustomerBonusController::class, 'index']);
            Route::get('/customer-bonuses/{id}/logs', [CustomerBonusController::class, 'logs']);
        });

        Route::middleware('role:admin,cashier')->group(function () {
            Route::post('/customer-bonuses', [CustomerBonusController::class, 'store']);
            Route::put('/customer-bonuses/{id}', [CustomerBonusController::class, 'update']);
            Route::delete('/customer-bonuses/{id}', [CustomerBonusController::class, 'destroy']);
            Route::post('/customer-bonuses/{id}/claim', [CustomerBonusController::class, 'claim']);
        });

        Route::prefix('superadmin')->middleware('role:superadmin')->group(function () {
            Route::get('/tenants', [SuperAdminController::class, 'index']);
            Route::post('/tenants', [SuperAdminController::class, 'store']);
            Route::put('/tenants/{id}', [SuperAdminController::class, 'update']);
            Route::patch('/tenants/{id}', [SuperAdminController::class, 'update']);
        });
    });
});

// Webhook Pembayaran Otomatis dari Notifikasi HP (DANA Bisnis, GoPay, BCA, dll)
Route::post('/webhook/payment-notification', [\App\Http\Controllers\Api\PaymentWebhookController::class, 'handle']);
Route::get('/webhook/payment-notification', [\App\Http\Controllers\Api\PaymentWebhookController::class, 'handle']);
