<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsurePasswordChanged
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user()?->must_change_password) {
            return response()->json([
                'status' => false,
                'message' => 'Ganti password sementara sebelum menggunakan aplikasi.',
                'must_change_password' => true,
            ], 423);
        }

        return $next($request);
    }
}
