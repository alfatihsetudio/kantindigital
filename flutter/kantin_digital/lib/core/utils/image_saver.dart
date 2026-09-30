import 'dart:typed_data';
import 'image_saver_stub.dart'
    if (dart.library.html) 'image_saver_web.dart' as saver;

class ImageSaver {
  static Future<bool> saveImage(Uint8List bytes, String filename) {
    return saver.saveImageBytes(bytes, filename);
  }

  static void openUrl(String url) {
    saver.openExternalUrl(url);
  }
}
