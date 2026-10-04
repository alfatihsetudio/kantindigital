import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/tenant_model.dart';
import 'demo_session_manager.dart';

class TenantService {
  static TenantModel? _cached;
  static String? _demoSubdomain;

  static String? get demoSubdomain => _demoSubdomain;

  static void setDemoSubdomain(String? sub) {
    _demoSubdomain = sub;
    _cached = null;
  }

  static void clearDemoSubdomain() {
    _demoSubdomain = null;
    _cached = null;
  }

  /// Deteksi apakah pengguna mengakses domain utama (ekasir.my.id) tanpa subdomain tenant
  static bool get isRootDomain {
    if (_demoSubdomain != null) return false;
    if (!kIsWeb) return false;
    return currentSubdomain == null;
  }

  /// Deteksi subdomain dari URL browser (Web) atau fallback
  static String? get currentSubdomain {
    if (_demoSubdomain != null) return _demoSubdomain;
    if (!kIsWeb) return null;
    final host = Uri.base.host.toLowerCase().trim();
    if (host.isEmpty ||
        host == 'localhost' ||
        host == '127.0.0.1' ||
        RegExp(r'^\d+\.\d+\.\d+\.\d+$').hasMatch(host)) {
      return null;
    }

    final parts = host.split('.');

    // Kasus 1: TLD 2 tingkat seperti .my.id, .co.id, .web.id
    // ekasir.my.id -> 3 parts: ['ekasir', 'my', 'id'] -> Root domain, tidak ada tenant
    // saycoffee.ekasir.my.id -> 4 parts: ['saycoffee', 'ekasir', 'my', 'id'] -> tenant: saycoffee
    final isTwoLevelTld =
        parts.length >= 2 &&
        (parts[parts.length - 2] == 'my' ||
            parts[parts.length - 2] == 'co' ||
            parts[parts.length - 2] == 'web' ||
            parts[parts.length - 2] == 'or' ||
            parts[parts.length - 2] == 'ac' ||
            parts[parts.length - 2] == 'sch') &&
        parts.last == 'id';

    if (isTwoLevelTld) {
      if (parts.length > 3) {
        final sub = parts.first;
        if (sub != 'www') return sub;
      }
      return null;
    }

    // Kasus 2: Domain standar seperti kasirdigital.com, kasir.test
    // kasirdigital.com -> 2 parts -> Root domain
    // saycoffee.kasirdigital.com -> 3 parts -> tenant: saycoffee
    if (parts.length >= 3) {
      final sub = parts.first;
      if (sub != 'www' && sub != 'ekasir' && sub != 'kasirdigital') {
        return sub;
      }
    }

    return null;
  }

  /// Fetch info tenant dari API
  static Future<TenantModel> fetchTenantInfo() async {
    if (_cached != null) return _cached!;

    if (_demoSubdomain != null || DemoSessionManager.isDemoMode) {
      _cached = DemoSessionManager.demoTenant;
      return DemoSessionManager.demoTenant;
    }

    // Jika di root domain (ekasir.my.id), gunakan profil platform root eKasir
    if (isRootDomain) {
      _cached = TenantModel.platformRoot;
      return TenantModel.platformRoot;
    }

    try {
      final client = ApiClient();
      final response = await client.get('/tenant/info');
      final tenant = TenantModel.fromJson(response['data']);
      _cached = tenant;
      return tenant;
    } catch (e) {
      debugPrint('TenantService: gagal fetch tenant info → $e');
      return TenantModel.fallback;
    }
  }

  /// Reset cache (untuk hot reload / testing)
  static void clearCache() => _cached = null;

  /// Return cached tenant or fallback
  static TenantModel get current {
    if (_demoSubdomain != null || DemoSessionManager.isDemoMode) {
      return DemoSessionManager.demoTenant;
    }
    return _cached ??
        (isRootDomain ? TenantModel.platformRoot : TenantModel.fallback);
  }
}
