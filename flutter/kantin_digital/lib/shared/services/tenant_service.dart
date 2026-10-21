import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../auth/auth_session.dart';
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

  static void setCached(TenantModel? tenant) {
    _cached = tenant;
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
    // saycoffee.my.id -> 3 parts: ['saycoffee', 'my', 'id'] -> tenant: saycoffee
    // www.saycoffee.my.id -> 4 parts -> tenant: saycoffee
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
        if (parts.first == 'www' && parts.length == 4) {
          final sub = parts[1];
          if (sub != 'ekasir' && sub != 'kasirdigital') return sub;
        }
        final sub = parts.first;
        if (sub != 'www') return sub;
      } else if (parts.length == 3) {
        final sub = parts.first;
        if (sub != 'www' && sub != 'ekasir' && sub != 'kasirdigital') {
          return sub;
        }
      }
      return null;
    }

    // Kasus 2: Domain standar seperti kasirdigital.com, saycoffee.com
    // kasirdigital.com -> 2 parts -> Root domain
    // saycoffee.com -> 2 parts -> tenant: saycoffee
    // saycoffee.kasirdigital.com -> 3 parts -> tenant: saycoffee
    if (parts.length >= 3) {
      if (parts.first == 'www' && parts.length == 3) {
        final sub = parts[1];
        if (sub != 'ekasir' && sub != 'kasirdigital') return sub;
      }
      final sub = parts.first;
      if (sub != 'www' && sub != 'ekasir' && sub != 'kasirdigital') {
        return sub;
      }
    } else if (parts.length == 2) {
      final sub = parts.first;
      if (sub != 'www' && sub != 'ekasir' && sub != 'kasirdigital') {
        return sub;
      }
    }

    return null;
  }

  /// Fetch info tenant dari API
  static Future<TenantModel> fetchTenantInfo({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cached != null) return _cached!;

    if (_demoSubdomain != null || DemoSessionManager.isDemoMode) {
      _cached = DemoSessionManager.demoTenant;
      return DemoSessionManager.demoTenant;
    }

    // Jika pengguna login dan memiliki tenant di AuthSession, gunakan itu sebagai fallback cepat
    final authTenant = AuthSession().tenant;

    // Jika di root domain (ekasir.my.id) dan belum login, gunakan profil platform root eKasir
    if (isRootDomain && authTenant == null && !AuthSession().isAuthenticated) {
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
      if (authTenant != null &&
          authTenant.id != 0 &&
          authTenant.name.isNotEmpty) {
        _cached = authTenant;
        return authTenant;
      }
      debugPrint('TenantService: gagal fetch tenant info → $e');
      return isRootDomain ? TenantModel.platformRoot : TenantModel.fallback;
    }
  }

  /// Reset cache (untuk hot reload / testing)
  static void clearCache() => _cached = null;

  /// Return cached tenant or fallback
  static TenantModel get current {
    if (_demoSubdomain != null || DemoSessionManager.isDemoMode) {
      return DemoSessionManager.demoTenant;
    }
    final authTenant = AuthSession().tenant;
    if (authTenant != null &&
        authTenant.id != 0 &&
        authTenant.name.isNotEmpty) {
      return authTenant;
    }
    return _cached ??
        (isRootDomain ? TenantModel.platformRoot : TenantModel.fallback);
  }
}
