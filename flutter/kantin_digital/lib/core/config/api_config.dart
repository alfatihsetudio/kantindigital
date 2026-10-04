import 'package:flutter/foundation.dart';
import 'environment.dart';

class ApiConfig {
  /// Konfigurasi API Base URL
  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.isNotEmpty) {
        // Jika di local development (localhost, 127.0.0.1, atau *.test), arahkan ke Laravel di port 8000
        if (uri.host == 'localhost' ||
            uri.host == '127.0.0.1' ||
            uri.host.endsWith('.test')) {
          final host = (uri.host == 'localhost' || uri.host == '127.0.0.1')
              ? uri.host
              : '127.0.0.1';
          return '${uri.scheme}://$host:8000/api';
        }
        final port = (uri.port == 80 || uri.port == 443 || uri.port == 0) ? '' : ':${uri.port}';
        return '${uri.scheme}://${uri.host}$port/api';
      }
      return 'http://127.0.0.1:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
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
