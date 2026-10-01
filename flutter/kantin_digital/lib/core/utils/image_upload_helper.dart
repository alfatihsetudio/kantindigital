import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:image/image.dart' as img;

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
  /// Membuka file dialog di browser/HP, membaca file gambar,
  /// melakukan kompresi & resize ke max 400x400, dan mengembalikan file JPEG kecil.
  static Future<CompressedImageFile?> pickAndCompressImage({
    int maxDimension = 400,
    int quality = 80,
  }) async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) return null;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoadEnd.first;

    final rawBytes = reader.result as Uint8List;

    final image = img.decodeImage(rawBytes);
    if (image == null) {
      throw const FormatException('File yang dipilih bukan gambar yang valid.');
    }

    img.Image resized = image;
    if (image.width > maxDimension || image.height > maxDimension) {
      if (image.width >= image.height) {
        resized = img.copyResize(image, width: maxDimension);
      } else {
        resized = img.copyResize(image, height: maxDimension);
      }
    }

    final compressedBytes = Uint8List.fromList(
      img.encodeJpg(resized, quality: quality),
    );
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return CompressedImageFile(
      bytes: compressedBytes,
      filename: 'image_$timestamp.jpg',
      mimeType: 'image/jpeg',
    );
  }
}
