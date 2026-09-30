class AppLogger {
  static bool enabled = true;

  static void debug(String message) {
    if (!enabled) return;
    // ignore: avoid_print
    print('[DEBUG] $message');
  }

  static void error(String message, [Object? err]) {
    if (!enabled) return;
    // ignore: avoid_print
    print('[ERROR] $message ${err ?? ''}');
  }
}

