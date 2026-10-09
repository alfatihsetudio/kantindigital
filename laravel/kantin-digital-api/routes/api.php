<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\QrisSettingController;
use App\Http\Controllers\Api\RegisterStoreController;
use App\Http\Controllers\Api\SuperAdminController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\TenantController;
use App\Http\Controllers\Api\ToppingController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

// Public (customer & self-service registration)
Route::get('/app-manifest.json', [\App\Http\Controllers\Web\MetaController::class, 'manifest']);
Route::get('/manifest.json', [\App\Http\Controllers\Web\MetaController::class, 'manifest']);
Route::get('/manifest.webmanifest', [\App\Http\Controllers\Web\MetaController::class, 'manifest']);
Route::get('/tenant/info', [TenantController::class, 'info']); // info tenant dari subdomain
Route::get('/menus', [MenuController::class, 'index']);
Route::get('/menus/{menu}/toppings', [ToppingController::class, 'forMenu']);
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

    Route::middleware('password.changed')->group(function () {
        Route::post('/tenant/update', [TenantController::class, 'update'])
            ->middleware('role:admin');
        Route::post('/tenant/store-status', [TenantController::class, 'updateStoreStatus'])
            ->middleware('role:admin,cashier');
        Route::post('/tenant/opening-hours', [TenantController::class, 'updateOpeningHours'])
            ->middleware('role:admin,cashier');

        Route::middleware('role:admin')->group(function () {
            Route::apiResource('menus', MenuController::class)->except(['index']);
            Route::post('/menus/{id}', [MenuController::class, 'update']);
            Route::apiResource('categories', CategoryController::class);
            Route::post('/categories/{id}/toggle', [CategoryController::class, 'toggle']);
            Route::apiResource('tables', TableController::class);
            Route::apiResource('toppings', ToppingController::class);
            Route::post('/users', [UserController::class, 'store']);
            Route::put('/users/{id}', [UserController::class, 'update']);
            Route::patch('/users/{id}', [UserController::class, 'update']);
            Route::delete('/users/{id}', [UserController::class, 'destroy']);

            Route::get('/qris-setting', [QrisSettingController::class, 'show']);
            Route::post('/qris-setting', [QrisSettingController::class, 'update']);
            Route::put('/qris-setting', [QrisSettingController::class, 'update']);
        });

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
