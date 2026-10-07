// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<String?> getGpsMapsUrl() async {
  try {
    final geo = html.window.navigator.geolocation;
    final pos = await geo.getCurrentPosition(
      enableHighAccuracy: true,
      timeout: const Duration(seconds: 12),
    );
    final coords = pos.coords;
    if (coords != null && coords.latitude != null && coords.longitude != null) {
      return 'https://maps.google.com/?q=${coords.latitude},${coords.longitude}';
    }
  } catch (_) {}
  return null;
}

void openMaps([String? url]) {
  try {
    final target = (url != null && url.trim().isNotEmpty)
        ? url.trim()
        : 'https://www.google.com/maps';
    html.window.open(target, '_blank');
  } catch (_) {}
}
