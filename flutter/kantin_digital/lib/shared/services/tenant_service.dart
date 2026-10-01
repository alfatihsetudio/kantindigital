import 'package:flutter/foundation.dart';
import '../../core/network/api_client.dart';
import '../models/tenant_model.dart';

class TenantService {
  static TenantModel? _cached;

  /// Deteksi subdomain dari URL browser (Web) atau fallback
  static String? get currentSubdomain {
    if (!kIsWeb) return null;
    final host = Uri.base.host; // e.g. saycoffee.kasirdigital.test
    final parts = host.split('.');
    if (parts.length >= 3) {
      return parts.first; // "saycoffee"
    }
    return null;
  }

  /// Fetch info tenant dari API
  static Future<TenantModel> fetchTenantInfo() async {
    if (_cached != null) return _cached!;

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
  static TenantModel get current => _cached ?? TenantModel.fallback;
}
