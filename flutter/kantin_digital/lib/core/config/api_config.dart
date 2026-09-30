import 'package:flutter/foundation.dart';
import 'environment.dart';

class ApiConfig {
  /// Konfigurasi API Base URL
  static String get baseUrl => kIsWeb 
      ? 'http://localhost:8000/api'
      : 'http://10.118.242.253:8000/api';

  /// URL Frontend Flutter Web (untuk QR Code)
  static String get webBaseUrl => kIsWeb
      ? 'http://localhost:8888'
      : 'http://10.118.242.253:8888';

  static const Environment environment = Environment.dev;
}

