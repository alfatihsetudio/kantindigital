import 'package:flutter/foundation.dart';
import 'environment.dart';

class ApiConfig {
  /// Konfigurasi API Base URL
  static String get baseUrl {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.host.isNotEmpty) {
        // Jika dibuka dari domain atau Laragon virtual host (*.test, *.my.id, dll),
        // gunakan host yang sama agar same-origin dan bebas dari blokir CORS / Private Network
        if (uri.host.endsWith('.test') || uri.host.contains('.')) {
          final port = (uri.port == 80 || uri.port == 443 || uri.port == 0) ? '' : ':${uri.port}';
          return '${uri.scheme}://${uri.host}$port/api';
        }
        // Jika di local development via flutter run dev server (localhost / 127.0.0.1 port non-80)
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          if (uri.port == 80 || uri.port == 0) {
            return '${uri.scheme}://${uri.host}/api';
          }
          return '${uri.scheme}://${uri.host}:8000/api';
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
