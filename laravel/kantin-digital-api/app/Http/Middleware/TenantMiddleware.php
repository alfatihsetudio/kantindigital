<?php

namespace App\Http\Middleware;

use App\Models\Tenant;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TenantMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $host = $request->getHost();
        $subdomain = null;

        // 1. Cek header X-Tenant atau query param
        if ($request->hasHeader('X-Tenant') && !empty($request->header('X-Tenant'))) {
            $subdomain = $request->header('X-Tenant');
        } elseif ($request->has('tenant') && !empty($request->get('tenant'))) {
            $subdomain = $request->get('tenant');
        } elseif (!filter_var($host, FILTER_VALIDATE_IP)) {
            // 2. Jika bukan IP, ambil subdomain dari hostname
            $parts = explode('.', $host);
            if (count($parts) >= 3) {
                $first = $parts[0];
                if ($first !== 'www' && $first !== 'kasirdigital' && $first !== 'ekasir') {
                    $subdomain = $first;
                }
            }
        }

        if ($subdomain) {
            $tenant = Tenant::where('subdomain', $subdomain)->where('is_active', true)->first();
            if (!$tenant) {
                return response()->json([
                    'status'  => false,
                    'message' => "Tenant '$subdomain' tidak ditemukan atau tidak aktif.",
                ], 404);
            }
            app()->instance('tenant', $tenant);
            $request->attributes->set('tenant', $tenant);
        } else {
            // 3. Fallback jika lewat IP lokal / localhost tanpa subdomain
            $defaultTenant = Tenant::where('is_active', true)->first();
            if ($defaultTenant) {
                app()->instance('tenant', $defaultTenant);
                $request->attributes->set('tenant', $defaultTenant);
            }
        }

        return $next($request);
    }
}
