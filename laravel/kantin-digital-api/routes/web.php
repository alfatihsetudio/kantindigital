<?php

use App\Http\Controllers\Web\MetaController;
use Illuminate\Support\Facades\Route;

// Catch-all route untuk Flutter Web SPA & Dynamic Social Media Previews
Route::get('/{any?}', [MetaController::class, 'render'])
    ->where('any', '^(?!api|uploads|storage).*$');
