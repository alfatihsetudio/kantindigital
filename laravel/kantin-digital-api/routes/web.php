<?php

use App\Http\Controllers\Web\MetaController;
use Illuminate\Support\Facades\Route;

// Dynamic PWA Manifest & Service Worker per Tenant
Route::get('/app-manifest.json', [MetaController::class, 'manifest']);
Route::get('/manifest.json', [MetaController::class, 'manifest']);
Route::get('/manifest.webmanifest', [MetaController::class, 'manifest']);
Route::get('/sw.js', [MetaController::class, 'serviceWorker']);

// Catch-all route untuk Flutter Web SPA & Dynamic Social Media Previews
Route::get('/{any?}', [MetaController::class, 'render'])
    ->where('any', '^(?!api|uploads|storage).*$');
