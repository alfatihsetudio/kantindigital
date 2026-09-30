import 'package:flutter/foundation.dart';
import 'environment.dart';

class ApiConfig {
  /// Konfigurasi API Base URL
  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.isNotEmpty) {
        final port = (uri.port == 80 || uri.port == 443 || uri.port == 0) ? '' : ':${uri.port}';
        // Jika berjalan di flutter debug web port (misal 8888), arahkan API ke port 80 pada host yang sama
        if (uri.port == 8888) {
          return '${uri.scheme}://${uri.host}/api';
        }
        return '${uri.scheme}://${uri.host}$port/api';
      }
      return 'http://192.168.0.8/api';
    }
    return 'http://192.168.0.8/api';
  }

  /// URL Frontend Flutter Web (untuk QR Code)
  static String get webBaseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.isNotEmpty) {
        final port = (uri.port == 80 || uri.port == 443 || uri.port == 0) ? '' : ':${uri.port}';
        return '${uri.scheme}://${uri.host}$port';
      }
      return 'http://192.168.0.8';
    }
    return 'http://192.168.0.8';
  }

  static const Environment environment = Environment.dev;
}
