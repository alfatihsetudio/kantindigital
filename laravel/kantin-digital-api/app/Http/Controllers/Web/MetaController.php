<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class MetaController extends Controller
{
    public function render(Request $request)
    {
        $host = $request->getHost();
        $subdomain = null;

        // 1. Cek query parameter atau header X-Tenant
        if ($request->has('tenant') && !empty($request->get('tenant'))) {
            $subdomain = $request->get('tenant');
        } elseif ($request->hasHeader('X-Tenant') && !empty($request->header('X-Tenant'))) {
            $subdomain = $request->header('X-Tenant');
        } elseif (!filter_var($host, FILTER_VALIDATE_IP)) {
            // Ambil subdomain dari host
            $parts = explode('.', $host);
            // Contoh: saycoffee.ekasir.my.id (4 parts) atau saycoffee.kantindigital.test (3 parts)
            if (count($parts) >= 3) {
                $first = $parts[0];
                if (!in_array($first, ['www', 'kasirdigital', 'ekasir', 'api', 'admin'])) {
                    $subdomain = $first;
                }
            }
        }

        $title = 'eKasir - Solusi Kasir & Menu Digital Multi-Tenant';
        $description = 'Platform aplikasi kasir dan menu digital online untuk kafe, resto, dan kantin.';
        $image = url('icons/Icon-512.png');
        $currentUrl = $request->fullUrl();

        if ($subdomain) {
            $tenant = Tenant::where('subdomain', $subdomain)
                ->where('is_active', true)
                ->first();

            if ($tenant) {
                $title = $tenant->meta_title ?: $tenant->name;
                
                if (!empty($tenant->meta_description)) {
                    $description = $tenant->meta_description;
                } elseif (!empty($tenant->address)) {
                    $description = $tenant->name . ' - ' . $tenant->address . '. Pesan menu favoritmu secara praktis dan nikmati kemudahannya!';
                } else {
                    $description = 'Pesan menu favoritmu di ' . $tenant->name . ' secara digital.';
                }

                $rawImg = $tenant->meta_image ?: $tenant->logo_url;
                if (!empty($rawImg)) {
                    if (str_starts_with($rawImg, 'http://') || str_starts_with($rawImg, 'https://')) {
                        // Jika URL mengandung host .test / localhost di mode produksi, sesuaikan dengan host request saat ini
                        $parsed = parse_url($rawImg);
                        if (!empty($parsed['path']) && str_starts_with($parsed['path'], '/uploads/')) {
                            $image = url(ltrim($parsed['path'], '/'));
                        } else {
                            $image = $rawImg;
                        }
                    } else {
                        $image = url(ltrim($rawImg, '/'));
                    }
                }
            }
        }

        // Cari file index.html Flutter Web
        $candidates = [
            public_path('index.html'),
            base_path('../../flutter/kantin_digital/build/web/index.html'),
            base_path('../flutter/kantin_digital/build/web/index.html'),
            '/www/wwwroot/ekasir.my.id/flutter/kantin_digital/build/web/index.html',
        ];

        $html = null;
        foreach ($candidates as $candidate) {
            if (File::exists($candidate)) {
                $html = File::get($candidate);
                break;
            }
        }

        if ($html === null) {
            $html = $this->defaultHtmlTemplate();
        }

        // Escape konten untuk HTML
        $safeTitle = htmlspecialchars($title, ENT_QUOTES, 'UTF-8');
        $safeDesc = htmlspecialchars($description, ENT_QUOTES, 'UTF-8');
        $safeImg = htmlspecialchars($image, ENT_QUOTES, 'UTF-8');
        $safeUrl = htmlspecialchars($currentUrl, ENT_QUOTES, 'UTF-8');

        // Ganti tag title dan description bawaan Flutter
        $html = preg_replace('/<title>.*?<\/title>/is', "<title>{$safeTitle}</title>", $html);
        $html = preg_replace('/<meta\s+name=["\']description["\']\s+content=["\'].*?["\']\s*\/?>/is', "<meta name=\"description\" content=\"{$safeDesc}\">", $html);
        $html = preg_replace('/<meta\s+name=["\']apple-mobile-web-app-title["\']\s+content=["\'].*?["\']\s*\/?>/is', "<meta name=\"apple-mobile-web-app-title\" content=\"{$safeTitle}\">", $html);

        // Siapkan Meta Tags OpenGraph & Twitter Card
        $socialMeta = <<<HTML
    <!-- Dynamic Social Media Preview (WhatsApp, Telegram, Facebook, Twitter) -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{$safeUrl}">
    <meta property="og:title" content="{$safeTitle}">
    <meta property="og:description" content="{$safeDesc}">
    <meta property="og:image" content="{$safeImg}">
    <meta property="og:image:secure_url" content="{$safeImg}">
    <meta property="og:image:width" content="600">
    <meta property="og:image:height" content="600">
    <meta property="og:site_name" content="{$safeTitle}">

    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:url" content="{$safeUrl}">
    <meta name="twitter:title" content="{$safeTitle}">
    <meta name="twitter:description" content="{$safeDesc}">
    <meta name="twitter:image" content="{$safeImg}">
HTML;

        // Sisipkan ke dalam <head>
        if (str_contains($html, '</head>')) {
            $html = str_replace('</head>', $socialMeta . "\n</head>", $html);
        }

        return response($html, 200)
            ->header('Content-Type', 'text/html; charset=UTF-8')
            ->header('Cache-Control', 'no-cache, private');
    }

    private function defaultHtmlTemplate(): string
    {
        return <<<'HTML'
<!DOCTYPE html>
<html>
<head>
  <base href="/">
  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="description" content="eKasir">
  <title>eKasir</title>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
HTML;
    }
}
