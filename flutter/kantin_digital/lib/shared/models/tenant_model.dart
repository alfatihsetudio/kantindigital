import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';
import '../utils/store_opening_hours.dart';

class TenantModel {
  final int id;
  final String subdomain;
  final String name;
  final String? logoUrl;
  final String primaryColor;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String openingHours;
  final bool isStoreOpen;
  final String plan;
  final bool isActive;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaImageUrl;
  final String? menuCodePrefix;
  final String promoBadgeText;
  final String promoMessage;
  final int promoDiscountPercent;
  final String promoScope;
  final List<int> promoMenuIds;
  final List<String> promoPaymentMethods;

  const TenantModel({
    required this.id,
    required this.subdomain,
    required this.name,
    this.logoUrl,
    this.primaryColor = '#00AA13',
    this.address,
    this.phone,
    this.whatsapp,
    this.openingHours = '08:00 - 22:00',
    this.isStoreOpen = false,
    this.plan = 'free',
    this.isActive = true,
    this.metaTitle,
    this.metaDescription,
    this.metaImageUrl,
    this.menuCodePrefix = 'SAY',
    this.promoBadgeText = 'Promo Hari Ini',
    this.promoMessage = 'Pesan Sekarang, Nikmati Kemudahannya!',
    this.promoDiscountPercent = 0,
    this.promoScope = 'all',
    this.promoMenuIds = const [],
    this.promoPaymentMethods = const ['qris'],
  });

  bool? isOpenAt(DateTime utcInstant) =>
      StoreOpeningHours.isOpenAt(openingHours, utcInstant);

  bool promoAppliesToPayment(String paymentMethod) {
    final configuredMethods = promoPaymentMethods
        .map((method) => method.toLowerCase().trim())
        .where((method) => method.isNotEmpty)
        .toSet();
    final allowedMethods = configuredMethods.isEmpty
        ? const {'qris'}
        : configuredMethods;
    return allowedMethods.contains(paymentMethod.toLowerCase().trim());
  }

  bool get hasPromo => promoDiscountPercent > 0;

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: (json['id'] as num).toInt(),
      subdomain: json['subdomain']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Kantin Digital',
      logoUrl: _resolveUrl(json['logo_url']),
      primaryColor: json['primary_color']?.toString() ?? '#00AA13',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      openingHours: (json['opening_hours'] != null &&
              json['opening_hours'].toString().trim().isNotEmpty)
          ? json['opening_hours'].toString().trim()
          : 'Setiap hari, 08:00 - 22:00',
      isStoreOpen: json['is_store_open'] == true || json['is_store_open'] == 1,
      plan: json['plan']?.toString() ?? 'free',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      metaTitle: json['meta_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
      metaImageUrl: _resolveUrl(json['meta_image'] ?? json['meta_image_url']),
      menuCodePrefix: json['menu_code_prefix']?.toString() ?? 'SAY',
      promoBadgeText: json['promo_badge_text']?.toString() ?? 'Promo Hari Ini',
      promoMessage:
          json['promo_message']?.toString() ??
          'Pesan Sekarang, Nikmati Kemudahannya!',
      promoDiscountPercent:
          (json['promo_discount_percent'] as num?)?.toInt() ?? 0,
      promoScope: json['promo_scope']?.toString() ?? 'all',
      promoMenuIds: (json['promo_menu_ids'] as List? ?? const [])
          .whereType<num>()
          .map((id) => id.toInt())
          .toList(),
      promoPaymentMethods:
          (json['promo_payment_methods'] as List? ?? const ['qris'])
              .map((method) => method.toString().toLowerCase().trim())
              .where((method) => method.isNotEmpty)
              .toList(),
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
      if (parsed != null &&
          parsed.host != Uri.base.host &&
          parsed.path.isNotEmpty) {
        return '${ApiConfig.webBaseUrl}${parsed.path}';
      }
    }
    return str;
  }

  /// Parse hex color string → Color
  Color get primaryColorValue {
    try {
      final hex = primaryColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF00AA13);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subdomain': subdomain,
      'name': name,
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'address': address,
      'phone': phone,
      'whatsapp': whatsapp,
      'opening_hours': openingHours,
      'is_store_open': isStoreOpen,
      'plan': plan,
      'is_active': isActive,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
      'meta_image': metaImageUrl,
      'menu_code_prefix': menuCodePrefix,
      'promo_badge_text': promoBadgeText,
      'promo_message': promoMessage,
      'promo_discount_percent': promoDiscountPercent,
      'promo_scope': promoScope,
      'promo_menu_ids': promoMenuIds,
      'promo_payment_methods': promoPaymentMethods,
    };
  }

  /// Default tenant platform utama (ekasir.my.id)
  static const TenantModel platformRoot = TenantModel(
    id: 0,
    subdomain: '',
    name: 'eKasir',
    primaryColor: '#2563EB',
    plan: 'enterprise',
  );

  /// Default tenant jika gagal load
  static const TenantModel fallback = platformRoot;
}

ImageProvider<Object>? tenantLogoImageProvider(String? logoUrl) {
  if (logoUrl == null || logoUrl.isEmpty) return null;
  if (!logoUrl.startsWith('data:image/')) return NetworkImage(logoUrl);

  final separator = logoUrl.indexOf(',');
  if (separator < 0) return null;
  try {
    return MemoryImage(base64Decode(logoUrl.substring(separator + 1)));
  } on FormatException {
    return null;
  }
}
