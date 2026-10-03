import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';

class MenuModel {
  final int id;
  final String? code;
  final String name;
  final String categoryName;
  final int price;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;

  const MenuModel({
    required this.id,
    this.code,
    required this.name,
    required this.categoryName,
    required this.price,
    this.imageUrl,
    this.description,
    this.isAvailable = true,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: (json['id'] as num).toInt(),
      code: json['code']?.toString(),
      name: (json['name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      price: (json['price'] as num).toInt(),
      imageUrl: _resolveUrl(json['image_url']),
      description: json['description']?.toString(),
      isAvailable: _parseAvailability(json['is_available']),
    );
  }

  static String? _resolveUrl(dynamic raw) {
    if (raw == null) return null;
    var str = raw.toString().trim();
    if (str.isEmpty) return null;
    if (str.startsWith('/')) {
      return '${ApiConfig.webBaseUrl}$str';
    }
    if (kIsWeb && Uri.base.scheme == 'https' && str.startsWith('http://')) {
      str = 'https://${str.substring(7)}';
    }
    if (kIsWeb && str.contains('/uploads/')) {
      final parsed = Uri.tryParse(str);
      if (parsed != null && parsed.host != Uri.base.host && parsed.path.isNotEmpty) {
        return '${ApiConfig.webBaseUrl}${parsed.path}';
      }
    }
    return str;
  }

  static bool _parseAvailability(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return true;
  }

  /// Nomor urut menu yang selaras dengan flyer Say Coffee (misal: "01", "02").
  String get sequenceNumber {
    // 1. Cek jika nama menu sudah memiliki awalan nomor (misal: "01. ", "1. ", "#01 ")
    final match = RegExp(r'^#?(\d{1,2})[\.\s\-:]').firstMatch(name.trim());
    if (match != null) {
      final numVal = int.tryParse(match.group(1) ?? '');
      if (numVal != null) {
        return numVal.toString().padLeft(2, '0');
      }
    }

    final upper = name.trim().toUpperCase();

    // 2. Pemetaan menu Kopi sesuai urutan Flyer (01 - 06)
    if (upper.contains('AREN')) return '01';
    if (upper.contains('BUTTER')) return '02';
    if (upper.contains('HAZEL HUG') || (upper.contains('HAZEL') && !upper.contains('CHOCO'))) return '03';
    if (upper.contains('MILKY')) return '04';
    if (upper.contains('SWEET CREAM')) return '05';
    if (upper.contains('BLACK BREW') || upper.contains('AMERICANO')) return '06';

    // 3. Pemetaan menu Non Kopi sesuai urutan Flyer (01 - 03)
    if (upper.contains('MATCHA')) return '01';
    if (upper.contains('CHOCO STORY')) return '02';
    if (upper.contains('CHOCO HAZEL')) return '03';

    return '';
  }

  /// Format kode menu lengkap dengan prefix profil (misal: "SAY-01").
  String formattedCode([String? prefix = 'SAY']) {
    final effectivePrefix = (prefix != null && prefix.trim().isNotEmpty)
        ? prefix.trim().toUpperCase()
        : 'SAY';

    if (code != null && code!.trim().isNotEmpty) {
      final cleanCode = code!.trim().toUpperCase();
      if (cleanCode.startsWith('$effectivePrefix-')) {
        return cleanCode;
      }
      return '$effectivePrefix-$cleanCode';
    }

    if (sequenceNumber.isNotEmpty) {
      return '$effectivePrefix-$sequenceNumber';
    }

    return '';
  }

  /// Urutan sorting menu agar presisi sesuai urutan di Flyer / Database kode.
  int get flyerOrder {
    if (code != null && code!.trim().isNotEmpty) {
      final parsed = int.tryParse(code!.replaceAll(RegExp(r'\D'), ''));
      if (parsed != null && parsed > 0) return parsed;
    }

    final upper = name.trim().toUpperCase();
    if (upper.contains('AREN')) return 1;
    if (upper.contains('BUTTER')) return 2;
    if (upper.contains('HAZEL HUG') || (upper.contains('HAZEL') && !upper.contains('CHOCO'))) return 3;
    if (upper.contains('MILKY')) return 4;
    if (upper.contains('SWEET CREAM')) return 5;
    if (upper.contains('BLACK BREW') || upper.contains('AMERICANO')) return 6;
    if (upper.contains('MATCHA')) return 7;
    if (upper.contains('CHOCO STORY')) return 8;
    if (upper.contains('CHOCO HAZEL')) return 9;

    final match = RegExp(r'^#?(\d{1,2})[\.\s\-:]').firstMatch(name.trim());
    if (match != null) {
      final parsed = int.tryParse(match.group(1) ?? '');
      if (parsed != null) return parsed;
    }

    return 100 + id;
  }

  /// Nama menu bersih tanpa awalan nomor urut ganda.
  String get displayName {
    final clean = name.replaceFirst(RegExp(r'^#?\d{1,2}[\.\s\-:]\s*'), '').trim();
    return clean.isNotEmpty ? clean : name;
  }
}
