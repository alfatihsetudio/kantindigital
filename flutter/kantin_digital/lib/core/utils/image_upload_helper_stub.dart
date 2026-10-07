import 'dart:convert';
import 'dart:typed_data';

class CompressedImageFile {
  const CompressedImageFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;

  String get dataUrl => 'data:$mimeType;base64,${base64Encode(bytes)}';
}

class ImageUploadHelper {
  static Future<CompressedImageFile?> pickAndCompressImage({
    int maxDimension = 400,
    int quality = 80,
  }) async {
    return null;
  }
}
