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
        // Endpoint publik untuk cek subdomain & pendaftaran tenant baru bersifat global
        if ($request->is('api/check-subdomain*') || $request->is('api/register-store*')) {
            return $next($request);
        }

        $host = $request->getHost();
        $subdomain = null;

        // 1. Cek header X-Tenant atau query param
        if ($request->hasHeader('X-Tenant') && ! empty($request->header('X-Tenant'))) {
            $subdomain = $request->header('X-Tenant');
        } elseif ($request->has('tenant') && ! empty($request->get('tenant'))) {
            $subdomain = $request->get('tenant');
        } elseif (! filter_var($host, FILTER_VALIDATE_IP)) {
            // 2. Jika bukan IP, ambil subdomain/tenant dari hostname
            $parts = explode('.', strtolower($host));
            if (count($parts) >= 3) {
                $first = $parts[0];
                if ($first === 'www' && count($parts) >= 4) {
                    $first = $parts[1];
                }
                if ($first !== 'www' && $first !== 'kasirdigital' && $first !== 'ekasir' && $first !== 'api' && $first !== 'admin') {
                    $subdomain = $first;
                }
            } elseif (count($parts) === 2) {
                $first = $parts[0];
                if ($first !== 'kasirdigital' && $first !== 'ekasir') {
                    $subdomain = $first;
                }
            }
        }

        if ($subdomain) {
            $lookupSubdomains = [$subdomain];
            if ($subdomain === 'sayutikopi') {
                $lookupSubdomains[] = 'saycoffee';
            } elseif ($subdomain === 'saycoffee') {
                $lookupSubdomains[] = 'sayutikopi';
            }

            $tenant = Tenant::whereIn('subdomain', $lookupSubdomains)
                ->where('is_active', true)
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                        ->orWhere('expires_at', '>', now());
                })
                ->first();
            if (! $tenant && $subdomain === 'demo') {
                $tenant = Tenant::firstOrCreate(
                    ['subdomain' => 'demo'],
                    [
                        'name' => 'DEMO RESTO & CAFE',
                        'menu_code_prefix' => 'DEMO',
                        'primary_color' => '#2563EB',
                        'address' => 'Kawasan Bisnis Demo No. 88, Jakarta',
                        'phone' => '081234567890',
                        'whatsapp' => '6287771262100',
                        'plan' => 'pro',
                        'is_active' => true,
                        'meta_title' => 'Demo eKasir - Self Order & POS Resto',
                        'meta_description' => 'Simulasi Sistem Pemesanan Mandiri & Kasir POS',
                    ]
                );
                if (! $tenant->is_active) {
                    $tenant->update(['is_active' => true]);
                }
            }

            if (! $tenant) {
                return response()->json([
                    'status' => false,
                    'message' => "Tenant '$subdomain' tidak ditemukan atau tidak aktif.",
                ], 404);
            }
            app()->instance('tenant', $tenant);
            $request->attributes->set('tenant', $tenant);
        } elseif ($host === 'localhost' || filter_var($host, FILTER_VALIDATE_IP)) {
            // Local IP access uses the first tenant; named root domains are platform-wide.
            $defaultTenant = Tenant::where('is_active', true)
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                        ->orWhere('expires_at', '>', now());
                })
                ->first();
            if ($defaultTenant) {
                app()->instance('tenant', $defaultTenant);
                $request->attributes->set('tenant', $defaultTenant);
            }
        }

        return $next($request);
    }
}
