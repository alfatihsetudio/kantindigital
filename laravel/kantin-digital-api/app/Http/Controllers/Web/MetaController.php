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
        if (app()->has('tenant')) {
            $bound = app('tenant');
            if ($bound instanceof Tenant) {
                return $bound;
            }
        }

        if ($request->attributes->has('tenant')) {
            $attr = $request->attributes->get('tenant');
            if ($attr instanceof Tenant) {
                return $attr;
            }
        }

        $subdomain = null;

        if ($request->filled('tenant')) {
            $subdomain = trim((string) $request->get('tenant'));
        } elseif ($request->hasHeader('X-Tenant') && !empty($request->header('X-Tenant'))) {
            $subdomain = trim((string) $request->header('X-Tenant'));
        } else {
            $host = $request->header('X-Forwarded-Host') ?: $request->getHost();
            if (str_contains($host, ',')) {
                $host = trim(explode(',', $host)[0]);
            }
            $host = explode(':', $host)[0];

            if (!filter_var($host, FILTER_VALIDATE_IP)) {
                $parts = explode('.', strtolower($host));
                if (count($parts) >= 3) {
                    $first = $parts[0];
                    if ($first === 'www' && count($parts) >= 4) {
                        $first = $parts[1];
                    }
                    if (!in_array($first, ['www', 'kasirdigital', 'ekasir', 'api', 'admin'], true)) {
                        $subdomain = $first;
                    }
                } elseif (count($parts) === 2) {
                    $first = $parts[0];
                    if (!in_array($first, ['kasirdigital', 'ekasir', 'api', 'admin'], true)) {
                        $subdomain = $first;
                    }
                }
            }
        }

        if (!empty($subdomain)) {
            try {
                return Tenant::where('subdomain', $subdomain)->first();
            } catch (\Throwable $e) {
                return null;
            }
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
        if (($request->header('X-Forwarded-Proto') === 'https' || $request->isSecure()) && str_starts_with($base, 'http://')) {
            $base = 'https://' . substr($base, 7);
        }

        $path = parse_url($rawImg, PHP_URL_PATH);
        if (!empty($path) && str_starts_with($path, '/uploads/')) {
            return $base . $path;
        }

        if (str_starts_with($rawImg, 'http://') || str_starts_with($rawImg, 'https://')) {
            if (($request->header('X-Forwarded-Proto') === 'https' || $request->isSecure()) && str_starts_with($rawImg, 'http://')) {
                return 'https://' . substr($rawImg, 7);
            }
            return $rawImg;
        }

        return $base . '/' . ltrim($rawImg, '/');
    }

    private function resolveTenantLogo(Request $request, ?Tenant $tenant, string $default): string
    {
        if (!$tenant) {
            return $default;
        }

        $rawImg = $tenant->logo_url ?: $tenant->meta_image;
        if (empty($rawImg)) {
            return $default;
        }

        $base = $request->getSchemeAndHttpHost();
        if (($request->header('X-Forwarded-Proto') === 'https' || $request->isSecure()) && str_starts_with($base, 'http://')) {
            $base = 'https://' . substr($base, 7);
        }

        $path = parse_url($rawImg, PHP_URL_PATH);
        if (!empty($path) && str_starts_with($path, '/uploads/')) {
            return $base . $path;
        }

        if (str_starts_with($rawImg, 'http://') || str_starts_with($rawImg, 'https://')) {
            if (($request->header('X-Forwarded-Proto') === 'https' || $request->isSecure()) && str_starts_with($rawImg, 'http://')) {
                return 'https://' . substr($rawImg, 7);
            }
            return $rawImg;
        }

        return $base . '/' . ltrim($rawImg, '/');
    }

    public function render(Request $request)
    {
        $tenant = $this->resolveTenant($request);

        $title = 'eKasir - Solusi Kasir & Menu Digital Multi-Tenant';
        $appName = 'eKasir';
        $description = 'Platform aplikasi kasir dan menu digital online untuk kafe, resto, dan kantin.';
        $image = url('icons/Icon-512.png');
        $logo = url('icons/Icon-512.png');
        $primaryColor = '#2563EB';
        $currentUrl = $request->fullUrl();

        if ($tenant) {
            $appName = $tenant->name;
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
            $logo = $this->resolveTenantLogo($request, $tenant, $logo);
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
        $safeAppName = htmlspecialchars($appName, ENT_QUOTES, 'UTF-8');
        $safeDesc = htmlspecialchars($description, ENT_QUOTES, 'UTF-8');
        $safeImg = htmlspecialchars($image, ENT_QUOTES, 'UTF-8');
        $safeLogo = htmlspecialchars($logo, ENT_QUOTES, 'UTF-8');
        $safeUrl = htmlspecialchars($currentUrl, ENT_QUOTES, 'UTF-8');
        $safeColor = htmlspecialchars($primaryColor, ENT_QUOTES, 'UTF-8');

        // 1. Ganti Title & Description & App Name
        $html = preg_replace('/<title>.*?<\/title>/is', "<title>{$safeTitle}</title>", $html);
        $html = preg_replace('/<meta\s+name=["\']description["\']\s+content=["\'].*?["\']\s*\/?>/is', "<meta name=\"description\" content=\"{$safeDesc}\">", $html);
        $html = preg_replace('/<meta\s+name=["\']apple-mobile-web-app-title["\']\s+content=["\'].*?["\']\s*\/?>/is', "<meta name=\"apple-mobile-web-app-title\" content=\"{$safeAppName}\">", $html);
        if (preg_match('/<meta\s+name=["\']application-name["\'][^>]*>/i', $html)) {
            $html = preg_replace('/<meta\s+name=["\']application-name["\']\s+content=["\'].*?["\']\s*\/?>/is', "<meta name=\"application-name\" content=\"{$safeAppName}\">", $html);
        } else {
            $html = str_replace('<head>', "<head>\n  <meta name=\"application-name\" content=\"{$safeAppName}\">", $html);
        }

        // 2. Ganti Favicon & Apple Touch Icon dengan Logo Tenant
        $html = preg_replace('/<link\s+rel=["\']icon["\'][^>]*>/is', "<link rel=\"icon\" href=\"{$safeLogo}\">\n  <link rel=\"shortcut icon\" href=\"{$safeLogo}\">", $html);
        $html = preg_replace('/<link\s+rel=["\']apple-touch-icon["\'][^>]*>/is', "<link rel=\"apple-touch-icon\" href=\"{$safeLogo}\">", $html);

        // 2b. Hubungkan link manifest ke dynamic manifest per tenant (/api/app-manifest.json agar dilayani langsung oleh Laravel dengan status 200 OK)
        $manifestQuery = $tenant ? '?tenant=' . urlencode($tenant->subdomain) : '';
        $manifestUrl = "/api/app-manifest.json{$manifestQuery}";
        $html = preg_replace('/<link\s+rel=["\']manifest["\'][^>]*>/is', "<link rel=\"manifest\" href=\"{$manifestUrl}\">", $html);

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
    <meta property="og:site_name" content="{$safeAppName}">

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
      <img src="{$safeLogo}" alt="{$safeAppName}" style="width:100%;height:100%;object-fit:cover;" onerror="this.style.display='none'">
    </div>
    <div style="font-size:16px;font-weight:700;color:#1e293b;letter-spacing:0.2px;margin-bottom:14px;">{$safeAppName}</div>
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

        // 4b. Interactive PWA Install Prompt Banner & Guide Modal untuk Konsumen
        $pwaHtml = <<<HTML
  <!-- Banner Anjuran Install Aplikasi PWA -->
  <div id="pwa-install-banner" style="display:none;position:fixed;bottom:20px;left:50%;transform:translateX(-50%) translateY(140%);width:calc(100% - 32px);max-width:480px;background:#ffffff;border-radius:20px;box-shadow:0 14px 40px rgba(0,0,0,0.16), 0 2px 10px rgba(0,0,0,0.06);border:1px solid #f1f5f9;padding:12px 14px;z-index:99998;box-sizing:border-box;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;transition:transform 0.4s cubic-bezier(0.16, 1, 0.3, 1);">
    <div style="display:flex;align-items:center;gap:12px;">
      <div style="width:46px;height:46px;border-radius:12px;overflow:hidden;flex-shrink:0;background:#f8fafc;box-shadow:0 3px 8px rgba(0,0,0,0.08);display:flex;align-items:center;justify-content:center;">
        <img src="{$safeLogo}" alt="{$safeAppName}" style="width:100%;height:100%;object-fit:cover;" onerror="this.src='/favicon.png'">
      </div>
      <div style="flex:1;min-width:0;">
        <div style="font-size:14px;font-weight:700;color:#0f172a;line-height:1.3;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
          Pasang Aplikasi {$safeAppName}
        </div>
        <div style="font-size:12px;color:#64748b;line-height:1.3;margin-top:2px;">
          Pesan lebih praktis & hemat kuota
        </div>
      </div>
      <div style="display:flex;align-items:center;gap:6px;flex-shrink:0;">
        <button id="pwa-install-action-btn" type="button" style="background:{$safeColor};color:#ffffff;border:none;border-radius:12px;padding:8px 14px;font-size:13px;font-weight:700;cursor:pointer;outline:none;box-shadow:0 4px 12px {$safeColor}40;">
          Install
        </button>
        <button id="pwa-later-btn" type="button" style="background:#f1f5f9;color:#64748b;border:none;border-radius:12px;padding:8px 10px;font-size:12px;font-weight:600;cursor:pointer;outline:none;">
          Nanti
        </button>
        <button id="pwa-dismiss-btn" type="button" aria-label="Tutup" style="background:transparent;border:none;color:#94a3b8;font-size:20px;line-height:1;width:26px;height:26px;display:flex;align-items:center;justify-content:center;cursor:pointer;border-radius:50%;padding:0;">
          &times;
        </button>
      </div>
    </div>
  </div>

  <!-- Modal Petunjuk Khusus iOS Safari (karena iOS tidak mendukung 1-klik API) -->
  <div id="pwa-guide-modal" style="display:none;position:fixed;inset:0;background:rgba(15,23,42,0.6);z-index:99999;align-items:center;justify-content:center;padding:20px;box-sizing:border-box;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;opacity:0;transition:opacity 0.25s ease;">
    <div style="background:#ffffff;border-radius:24px;max-width:380px;width:100%;padding:24px;box-shadow:0 20px 50px rgba(0,0,0,0.25);position:relative;">
      <div style="text-align:center;margin-bottom:18px;">
        <div style="width:60px;height:60px;border-radius:16px;overflow:hidden;margin:0 auto 12px;background:#f8fafc;box-shadow:0 4px 14px rgba(0,0,0,0.1);">
          <img src="{$safeLogo}" alt="{$safeAppName}" style="width:100%;height:100%;object-fit:cover;" onerror="this.src='/favicon.png'">
        </div>
        <div style="font-size:17px;font-weight:800;color:#0f172a;">Pasang ke Layar Utama</div>
        <div style="font-size:13px;color:#64748b;margin-top:4px;">Akses {$safeAppName} langsung dari HP tanpa buka browser!</div>
      </div>
      <div style="display:flex;flex-direction:column;gap:12px;font-size:13px;color:#334155;line-height:1.6;margin-bottom:20px;">
        <div style="display:flex;align-items:flex-start;gap:10px;">
          <span style="background:#eff6ff;color:#2563eb;width:24px;height:24px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;flex-shrink:0;">1</span>
          <span>Ketuk tombol <strong>Bagikan / Share</strong> (ikon <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline;vertical-align:middle;"><path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" y1="2" x2="12" y2="15"/></svg>) di bilah bawah Safari.</span>
        </div>
        <div style="display:flex;align-items:flex-start;gap:10px;">
          <span style="background:#eff6ff;color:#2563eb;width:24px;height:24px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;flex-shrink:0;">2</span>
          <span>Gulir dan pilih <strong>"Tambah ke Layar Utama" (Add to Home Screen)</strong>.</span>
        </div>
        <div style="display:flex;align-items:flex-start;gap:10px;">
          <span style="background:#eff6ff;color:#2563eb;width:24px;height:24px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-weight:700;flex-shrink:0;">3</span>
          <span>Ketuk <strong>Tambah</strong> di pojok kanan atas.</span>
        </div>
      </div>
      <button id="pwa-guide-close-btn" type="button" style="width:100%;background:{$safeColor};color:#ffffff;border:none;border-radius:14px;padding:12px;font-size:14px;font-weight:700;cursor:pointer;outline:none;">
        Saya Mengerti
      </button>
    </div>
  </div>

  <script>
    (function() {
      var deferredPrompt = null;
      var banner = document.getElementById('pwa-install-banner');
      var actionBtn = document.getElementById('pwa-install-action-btn');
      var laterBtn = document.getElementById('pwa-later-btn');
      var dismissBtn = document.getElementById('pwa-dismiss-btn');
      var modal = document.getElementById('pwa-guide-modal');
      var modalCloseBtn = document.getElementById('pwa-guide-close-btn');

      var isIos = /iphone|ipad|ipod/.test(navigator.userAgent.toLowerCase());
      var isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
                         window.navigator.standalone === true ||
                         document.referrer.includes('android-app://');

      var path = window.location.pathname.toLowerCase();
      var isStaffRoute = path.startsWith('/admin') || path.startsWith('/cashier') || path.startsWith('/manager') || path.startsWith('/superadmin');

      if (isStandalone || isStaffRoute) {
        return;
      }

      function isDismissed() {
        try {
          if (sessionStorage.getItem('pwa_prompt_dismissed') === '1') return true;
        } catch (e) {}
        return false;
      }

      function showBanner() {
        if (!banner || isDismissed()) return;
        banner.style.display = 'block';
        setTimeout(function() {
          banner.style.transform = 'translateX(-50%) translateY(0)';
        }, 50);
      }

      function hideBanner(saveDismiss) {
        if (!banner) return;
        banner.style.transform = 'translateX(-50%) translateY(140%)';
        setTimeout(function() {
          banner.style.display = 'none';
        }, 400);
        if (saveDismiss) {
          try {
            sessionStorage.setItem('pwa_prompt_dismissed', '1');
          } catch (e) {}
        }
      }

      // 1. Tangkap event instalasi resmi browser (Chrome Android / Edge / Desktop)
      window.addEventListener('beforeinstallprompt', function(e) {
        e.preventDefault();
        deferredPrompt = e;
        showBanner();
      });

      // 2. Jika sudah berhasil terinstall
      window.addEventListener('appinstalled', function() {
        deferredPrompt = null;
        hideBanner(true);
      });

      // 3. Tampilkan banner setelah halaman termuat
      setTimeout(showBanner, 1200);
      window.addEventListener('flutter-first-frame', function() {
        setTimeout(showBanner, 800);
      });

      // 4. Tombol "Install" diklik
      if (actionBtn) {
        actionBtn.addEventListener('click', function() {
          if (deferredPrompt) {
            // Langsung munculkan dialog instalasi resmi browser (1-klik tanpa manual)
            deferredPrompt.prompt();
            deferredPrompt.userChoice.then(function(choice) {
              hideBanner(true);
              deferredPrompt = null;
            });
          } else if (isIos && modal) {
            // Khusus iOS Safari (Apple tidak mendukung event auto-install)
            modal.style.display = 'flex';
            setTimeout(function() { modal.style.opacity = '1'; }, 20);
          } else {
            actionBtn.innerText = 'Memproses...';
            var attempts = 0;
            var checkInterval = setInterval(function() {
              attempts++;
              if (deferredPrompt) {
                clearInterval(checkInterval);
                actionBtn.innerText = 'Install';
                deferredPrompt.prompt();
                deferredPrompt.userChoice.then(function() {
                  hideBanner(true);
                  deferredPrompt = null;
                });
              } else if (attempts >= 10) {
                clearInterval(checkInterval);
                actionBtn.innerText = 'Install';
                if (modal && modalSteps) {
                  modalSteps.innerHTML = '<div style="font-size:13px;line-height:1.6;color:#334155;">Jika dialog otomatis tidak muncul, aplikasi mungkin sudah terpasang di HP Anda, atau dapat dipasang melalui menu <strong>titik tiga (⋮)</strong> di pojok kanan atas browser > pilih <strong>Install aplikasi</strong>.</div>';
                  modal.style.display = 'flex';
                  setTimeout(function() { modal.style.opacity = '1'; }, 20);
                }
              }
            }, 300);
          }
        });
      }

      // 5. Tombol "Nanti" (Menolak install - sembunyikan ajakan)
      if (laterBtn) {
        laterBtn.addEventListener('click', function(e) {
          e.stopPropagation();
          hideBanner(true);
        });
      }

      // 6. Tombol "✕" (Tutup - sembunyikan ajakan)
      if (dismissBtn) {
        dismissBtn.addEventListener('click', function(e) {
          e.stopPropagation();
          hideBanner(true);
        });
      }

      // 7. Tutup modal panduan iOS
      if (modalCloseBtn) {
        modalCloseBtn.addEventListener('click', function() {
          if (modal) {
            modal.style.opacity = '0';
            setTimeout(function() { modal.style.display = 'none'; }, 250);
          }
          hideBanner(true);
        });
      }
      if (modal) {
        modal.addEventListener('click', function(e) {
          if (e.target === modal) {
            modal.style.opacity = '0';
            setTimeout(function() { modal.style.display = 'none'; }, 250);
            hideBanner(true);
          }
        });
      }
    })();
  </script>
HTML;

        if (str_contains($html, '<body>')) {
            $html = str_replace('<body>', "<body>\n{$splashHtml}\n{$pwaHtml}", $html);
        }

        // 5. Dynamic Cache-Busting for flutter_bootstrap.js (always existing in public/)
        $bootstrapFile = public_path('flutter_bootstrap.js');
        $bootstrapVersion = File::exists($bootstrapFile) ? File::lastModified($bootstrapFile) : time();
        $html = preg_replace('/flutter_bootstrap(\.v[0-9]+)?\.js(\?[^"\'\s>]*)?/i', "flutter_bootstrap.js?v={$bootstrapVersion}_" . time(), $html);

        return response($html, 200)
            ->header('Content-Type', 'text/html; charset=UTF-8')
            ->header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0, post-check=0, pre-check=0')
            ->header('Pragma', 'no-cache')
            ->header('Expires', '0');
    }

    public function manifest(Request $request)
    {
        $tenant = $this->resolveTenant($request);

        $name = 'eKasir';
        $shortName = 'eKasir';
        $primaryColor = '#2563EB';
        $defaultLogo = url('icons/Icon-512.png');
        $logo = $defaultLogo;
        $id = '/';
        $startUrl = '/';

        if ($tenant) {
            $name = $tenant->name;
            $shortName = $tenant->name;
            $primaryColor = $tenant->primary_color ?: '#6F4E37';
            $logo = $this->resolveTenantLogo($request, $tenant, $defaultLogo);
            $id = '/?tenant=' . urlencode($tenant->subdomain);
            $startUrl = '/?tenant=' . urlencode($tenant->subdomain);
        }

        $ext = strtolower(pathinfo(parse_url($logo, PHP_URL_PATH) ?: '', PATHINFO_EXTENSION));
        $mimeType = match ($ext) {
            'jpg', 'jpeg' => 'image/jpeg',
            'webp' => 'image/webp',
            default => 'image/png',
        };

        $manifestLogo = $logo;
        $parsedPath = parse_url($logo, PHP_URL_PATH);
        if (!empty($parsedPath) && (str_starts_with($parsedPath, '/uploads/') || str_starts_with($parsedPath, '/icons/'))) {
            $manifestLogo = $parsedPath;
        } elseif (str_starts_with($manifestLogo, 'http://')) {
            $manifestLogo = 'https://' . substr($manifestLogo, 7);
        }

        $icons = [
            [
                'src' => $manifestLogo,
                'sizes' => '192x192',
                'type' => $mimeType,
                'purpose' => 'any',
            ],
            [
                'src' => $manifestLogo,
                'sizes' => '512x512',
                'type' => $mimeType,
                'purpose' => 'any',
            ],
            [
                'src' => $manifestLogo,
                'sizes' => '512x512',
                'type' => $mimeType,
                'purpose' => 'maskable',
            ],
        ];

        if ($manifestLogo !== '/icons/Icon-512.png') {
            $icons[] = [
                'src' => '/icons/Icon-192.png',
                'sizes' => '192x192',
                'type' => 'image/png',
                'purpose' => 'any',
            ];
            $icons[] = [
                'src' => '/icons/Icon-512.png',
                'sizes' => '512x512',
                'type' => 'image/png',
                'purpose' => 'any',
            ];
        }

        $manifest = [
            'id' => $id,
            'name' => $name,
            'short_name' => $shortName,
            'start_url' => $startUrl,
            'scope' => '/',
            'display' => 'standalone',
            'background_color' => '#FFFFFF',
            'theme_color' => $primaryColor,
            'description' => "Menu digital & pemesanan {$name}",
            'orientation' => 'portrait-primary',
            'prefer_related_applications' => false,
            'icons' => $icons,
        ];

        return response()->json($manifest)
            ->header('Content-Type', 'application/manifest+json; charset=UTF-8')
            ->header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
            ->header('Pragma', 'no-cache')
            ->header('Expires', '0')
            ->header('Access-Control-Allow-Origin', '*');
    }

    public function serviceWorker(Request $request)
    {
        $swPath = public_path('sw.js');
        if (!File::exists($swPath)) {
            $swPath = base_path('../flutter/kantin_digital/web/sw.js');
        }

        $content = File::exists($swPath)
            ? File::get($swPath)
            : "self.addEventListener('install', e => self.skipWaiting()); self.addEventListener('activate', e => e.waitUntil(self.clients.claim())); self.addEventListener('fetch', e => e.respondWith(fetch(e.request)));";

        return response($content, 200)
            ->header('Content-Type', 'application/javascript; charset=UTF-8')
            ->header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
            ->header('Pragma', 'no-cache')
            ->header('Expires', '0');
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
