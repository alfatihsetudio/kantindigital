import 'package:flutter/foundation.dart';
import '../../core/config/api_config.dart';

class MenuModel {
  final int id;
  final String name;
  final String categoryName;
  final int price;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;

  const MenuModel({
    required this.id,
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
    final str = raw.toString().trim();
    if (str.isEmpty) return null;
    if (str.startsWith('/')) {
      return '${ApiConfig.webBaseUrl}$str';
    }
    if (kIsWeb && (str.contains('.test') || str.contains('localhost')) && !Uri.base.host.contains('.test') && !Uri.base.host.contains('localhost')) {
      final parsed = Uri.tryParse(str);
      if (parsed != null && parsed.path.isNotEmpty) {
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
}
