<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;

class MetaController extends Controller
{
    private function resolveTenant(Request $request): ?Tenant
    {
        $host = $request->getHost();
        $subdomain = null;

        if ($request->has('tenant') && !empty($request->get('tenant'))) {
            $subdomain = $request->get('tenant');
        } elseif ($request->hasHeader('X-Tenant') && !empty($request->header('X-Tenant'))) {
            $subdomain = $request->header('X-Tenant');
        } elseif (!filter_var($host, FILTER_VALIDATE_IP)) {
            $parts = explode('.', $host);
            if (count($parts) >= 3) {
                $first = $parts[0];
                if (!in_array($first, ['www', 'kasirdigital', 'ekasir', 'api', 'admin'])) {
                    $subdomain = $first;
                }
            }
        }

        if ($subdomain) {
            return Tenant::where('subdomain', $subdomain)
                ->where('is_active', true)
                ->first();
        }

        return null;
    }

    private function resolveTenantImage(Request $request, ?Tenant $tenant, string $default): string
    {
        if (!$tenant) {
            return $default;
        }

        $rawImg = $tenant->meta_image ?: $tenant->logo_url;
        if (empty($rawImg)) {
            return $default;
        }

        $base = $request->getSchemeAndHttpHost();
        $path = parse_url($rawImg, PHP_URL_PATH);
        if (!empty($path) && str_starts_with($path, '/uploads/')) {
            return $base . $path;
        }

        if (str_starts_with($rawImg, 'http://') || str_starts_with($rawImg, 'https://')) {
            return $rawImg;
        }

        return $base . '/' . ltrim($rawImg, '/');
    }

    public function render(Request $request)
    {
        $tenant = $this->resolveTenant($request);

        $title = 'eKasir - Solusi Kasir & Menu Digital Multi-Tenant';
        $description = 'Platform aplikasi kasir dan menu digital online untuk kafe, resto, dan kantin.';
        $image = url('icons/Icon-512.png');
        $primaryColor = '#2563EB';
        $currentUrl = $request->fullUrl();

        if ($tenant) {
            $title = $tenant->meta_title ?: $tenant->name;
            $primaryColor = $tenant->primary_color ?: '#6F4E37';

            if (!empty($tenant->meta_description)) {
                $description = $tenant->meta_description;
            } elseif (!empty($tenant->address)) {
                $description = $tenant->name . ' - ' . $tenant->address . '. Pesan menu favoritmu secara praktis dan nikmati kemudahannya!';
            } else {
                $description = 'Pesan menu favoritmu di ' . $tenant->name . ' secara digital.';
            }

            $image = $this->resolveTenantImage($request, $tenant, $image);
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
        $safeColor = htmlspecialchars($primaryColor, ENT_QUOTES, 'UTF-8');

        // 1. Ganti Title & Description
        $html = preg_replace('/<title>.*?<\/title>/is', "<title>{$safeTitle}</title>", $html);
        $html = preg_replace('/<meta\s+name=["\']description["\']\s+content=["\'].*?["\']\s*\/?>/is', "<meta name=\"description\" content=\"{$safeDesc}\">", $html);
        $html = preg_replace('/<meta\s+name=["\']apple-mobile-web-app-title["\']\s+content=["\'].*?["\']\s*\/?>/is', "<meta name=\"apple-mobile-web-app-title\" content=\"{$safeTitle}\">", $html);

        // 2. Ganti Favicon & Apple Touch Icon dengan Logo Tenant
        $html = preg_replace('/<link\s+rel=["\']icon["\'][^>]*>/is', "<link rel=\"icon\" href=\"{$safeImg}\">\n  <link rel=\"shortcut icon\" href=\"{$safeImg}\">", $html);
        $html = preg_replace('/<link\s+rel=["\']apple-touch-icon["\'][^>]*>/is', "<link rel=\"apple-touch-icon\" href=\"{$safeImg}\">", $html);

        // 3. Siapkan Meta Tags OpenGraph & Twitter Card
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

        if (str_contains($html, '</head>')) {
            $html = str_replace('</head>', $socialMeta . "\n</head>", $html);
        }

        // 4. Loading Splash Screen dengan Logo Tenant saat Flutter sedang di-download
        $splashHtml = <<<HTML
  <div id="app-splash" style="position:fixed;inset:0;background:#ffffff;display:flex;flex-direction:column;align-items:center;justify-content:center;z-index:99999;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
    <div style="width:76px;height:76px;border-radius:18px;overflow:hidden;box-shadow:0 8px 24px rgba(0,0,0,0.08);background:#f8fafc;display:flex;align-items:center;justify-content:center;margin-bottom:14px;">
      <img src="{$safeImg}" alt="{$safeTitle}" style="width:100%;height:100%;object-fit:cover;" onerror="this.style.display='none'">
    </div>
    <div style="font-size:16px;font-weight:700;color:#1e293b;letter-spacing:0.2px;margin-bottom:14px;">{$safeTitle}</div>
    <div style="width:26px;height:26px;border:3px solid #e2e8f0;border-top-color:{$safeColor};border-radius:50%;animation:splash-spin 0.8s linear infinite;"></div>
  </div>
  <style>
    @keyframes splash-spin { to { transform: rotate(360deg); } }
  </style>
  <script>
    window.addEventListener('flutter-first-frame', function() {
      var s = document.getElementById('app-splash');
      if (s) {
        s.style.opacity = '0';
        s.style.transition = 'opacity 0.25s ease';
        setTimeout(function(){ s.remove(); }, 250);
      }
    });
  </script>
HTML;

        if (str_contains($html, '<body>')) {
            $html = str_replace('<body>', "<body>\n{$splashHtml}", $html);
        }

        return response($html, 200)
            ->header('Content-Type', 'text/html; charset=UTF-8')
            ->header('Cache-Control', 'no-cache, private');
    }

    public function manifest(Request $request)
    {
        $tenant = $this->resolveTenant($request);

        $name = 'eKasir';
        $shortName = 'eKasir';
        $primaryColor = '#2563EB';
        $image = url('icons/Icon-512.png');

        if ($tenant) {
            $name = $tenant->meta_title ?: $tenant->name;
            $shortName = $tenant->name;
            $primaryColor = $tenant->primary_color ?: '#6F4E37';
            $image = $this->resolveTenantImage($request, $tenant, $image);
        }

        $manifest = [
            'name' => $name,
            'short_name' => $shortName,
            'start_url' => '.',
            'display' => 'standalone',
            'background_color' => '#FFFFFF',
            'theme_color' => $primaryColor,
            'description' => "Menu digital & pemesanan {$name}",
            'orientation' => 'portrait-primary',
            'prefer_related_applications' => false,
            'icons' => [
                [
                    'src' => $image,
                    'sizes' => '192x192',
                    'type' => 'image/png',
                ],
                [
                    'src' => $image,
                    'sizes' => '512x512',
                    'type' => 'image/png',
                ],
            ],
        ];

        return response()->json($manifest)
            ->header('Content-Type', 'application/manifest+json')
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
