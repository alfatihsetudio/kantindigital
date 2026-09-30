<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\MenuController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\CategoryController;
use App\Http\Controllers\Api\TableController;
use App\Http\Controllers\Api\ToppingController;
use App\Http\Controllers\Api\UserController;

// Public (customer)
Route::get('/menus', [MenuController::class, 'index']);
Route::post('/orders', [OrderController::class, 'store']);
Route::get('/orders/{code}', [OrderController::class, 'show']);

// Admin / Management Resource Endpoints
Route::apiResource('menus', MenuController::class)->except(['index']);
Route::apiResource('categories', CategoryController::class);
Route::apiResource('tables', TableController::class);
Route::apiResource('toppings', ToppingController::class);
Route::apiResource('users', UserController::class);

// Auth (staff: admin/kasir/dapur)
Route::post('/login', [AuthController::class, 'login']);
Route::get('/kitchen/orders', [OrderController::class, 'indexForKitchen']);
Route::get('/cashier/orders', [OrderController::class, 'indexForCashier']);
Route::get('/manager/stats', [OrderController::class, 'salesStats']);
Route::post('/orders/{order}/status', [OrderController::class, 'updateStatus']);
Route::patch('/orders/{order}/status', [OrderController::class, 'updateStatus']);

