import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';

class ShowcaseMenuSample {
  final String name;
  final num price;
  final String? imageUrl;

  const ShowcaseMenuSample({
    required this.name,
    required this.price,
    this.imageUrl,
  });

  factory ShowcaseMenuSample.fromJson(Map<String, dynamic> json) {
    return ShowcaseMenuSample(
      name: json['name']?.toString() ?? '',
      price: json['price'] is num ? json['price'] as num : 0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class ShowcaseStoreModel {
  final int id;
  final String name;
  final String subdomain;
  final String storeUrl;
  final String? logoUrl;
  final String primaryColor;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String? metaDescription;
  final int menusCount;
  final int categoriesCount;
  final String? createdAt;
  final List<ShowcaseMenuSample> sampleMenus;

  const ShowcaseStoreModel({
    required this.id,
    required this.name,
    required this.subdomain,
    required this.storeUrl,
    this.logoUrl,
    this.primaryColor = '#16A34A',
    this.address,
    this.phone,
    this.whatsapp,
    this.metaDescription,
    this.menusCount = 0,
    this.categoriesCount = 0,
    this.createdAt,
    this.sampleMenus = const [],
  });

  factory ShowcaseStoreModel.fromJson(Map<String, dynamic> json) {
    var rawSamples = json['sample_menus'];
    List<ShowcaseMenuSample> samples = [];
    if (rawSamples is List) {
      samples = rawSamples
          .map((e) => ShowcaseMenuSample.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ShowcaseStoreModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? 'Toko eKasir',
      subdomain: json['subdomain']?.toString() ?? '',
      storeUrl: json['store_url']?.toString() ??
          'https://${json['subdomain']}.ekasir.my.id',
      logoUrl: _resolveUrl(json['logo_url']),
      primaryColor: json['primary_color']?.toString() ?? '#16A34A',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      metaDescription: json['meta_description']?.toString(),
      menusCount: (json['menus_count'] as num?)?.toInt() ?? 0,
      categoriesCount: (json['categories_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at']?.toString(),
      sampleMenus: samples,
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

  Color get primaryColorValue {
    try {
      final hex = primaryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF16A34A);
    }
  }

  String get displayDomain {
    final uri = Uri.tryParse(storeUrl);
    if (uri != null && uri.host.isNotEmpty) {
      return uri.host;
    }
    return '$subdomain.ekasir.my.id';
  }
}
