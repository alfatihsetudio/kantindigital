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
  final String? whatsappNumber;
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
  final String voucherPromoMode;
  final List<DeliveryDiscountTier> deliveryDiscountTiers;
  final String orderNotificationSound;
  final bool isCustomerBonusActive;
  final int customerBonusPercent;
  final int customerBonusMinSpend;
  final bool isTablesActive;

  const TenantModel({
    required this.id,
    required this.subdomain,
    required this.name,
    this.logoUrl,
    this.primaryColor = '#00AA13',
    this.address,
    this.phone,
    this.whatsapp,
    this.whatsappNumber,
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
    this.voucherPromoMode = 'both',
    this.deliveryDiscountTiers = const [],
    this.orderNotificationSound = 'dingdong',
    this.isCustomerBonusActive = true,
    this.customerBonusPercent = 0,
    this.customerBonusMinSpend = 0,
    this.isTablesActive = true,
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

  bool get allowsVoucher => voucherPromoMode != 'promo_only';
  bool get allowsGeneralPromo => voucherPromoMode != 'voucher_only';
  bool get hasPromo => promoDiscountPercent > 0 && allowsGeneralPromo;

  String? get confirmationPhoneNumber {
    if (whatsappNumber != null && whatsappNumber!.trim().isNotEmpty) {
      return whatsappNumber!.trim();
    }
    if (whatsapp != null && whatsapp!.trim().isNotEmpty) {
      return whatsapp!.trim();
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      return phone!.trim();
    }
    return null;
  }

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    final rawMode = json['voucher_promo_mode']?.toString().trim() ?? '';
    return TenantModel(
      id: (json['id'] as num).toInt(),
      subdomain: json['subdomain']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Kantin Digital',
      logoUrl: _resolveUrl(json['logo_url']),
      primaryColor: json['primary_color']?.toString() ?? '#00AA13',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      whatsappNumber: json['whatsapp_number']?.toString() ??
          json['whatsapp']?.toString() ??
          json['phone']?.toString(),
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
      voucherPromoMode:
          const {'both', 'single', 'voucher_only', 'promo_only'}.contains(rawMode)
              ? rawMode
              : 'both',
      deliveryDiscountTiers: (json['delivery_discount_tiers'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => DeliveryDiscountTier.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      orderNotificationSound: (json['order_notification_sound'] != null &&
              json['order_notification_sound'].toString().trim().isNotEmpty)
          ? json['order_notification_sound'].toString().trim()
          : 'dingdong',
      isCustomerBonusActive: json['is_customer_bonus_active'] == null ||
          json['is_customer_bonus_active'] == true ||
          json['is_customer_bonus_active'] == 1,
      customerBonusPercent:
          (json['customer_bonus_percent'] as num?)?.toInt() ?? 0,
      customerBonusMinSpend:
          (json['customer_bonus_min_spend'] as num?)?.toInt() ?? 0,
      isTablesActive: json['is_tables_active'] == null ||
          json['is_tables_active'] == true ||
          json['is_tables_active'] == 1 ||
          json['is_tables_active'] == '1',
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
      'whatsapp_number': whatsappNumber,
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
      'voucher_promo_mode': voucherPromoMode,
      'delivery_discount_tiers':
          deliveryDiscountTiers.map((t) => t.toJson()).toList(),
      'order_notification_sound': orderNotificationSound,
      'is_customer_bonus_active': isCustomerBonusActive,
      'customer_bonus_percent': customerBonusPercent,
      'customer_bonus_min_spend': customerBonusMinSpend,
      'is_tables_active': isTablesActive,
    };
  }

  /// Menghitung diskon pengantaran berdasarkan jumlah seluruh item (cup) di keranjang
  int calculateDeliveryDiscount(int totalQuantity) {
    if (deliveryDiscountTiers.isEmpty || totalQuantity <= 0) return 0;
    final sorted = List<DeliveryDiscountTier>.from(deliveryDiscountTiers)
      ..sort((a, b) => b.minQty.compareTo(a.minQty));
    for (final tier in sorted) {
      if (totalQuantity >= tier.minQty) {
        return tier.discountAmount;
      }
    }
    return 0;
  }

  /// Ambil tier pengantaran yang sedang aktif
  DeliveryDiscountTier? getActiveDeliveryTier(int totalQuantity) {
    if (deliveryDiscountTiers.isEmpty || totalQuantity <= 0) return null;
    final sorted = List<DeliveryDiscountTier>.from(deliveryDiscountTiers)
      ..sort((a, b) => b.minQty.compareTo(a.minQty));
    for (final tier in sorted) {
      if (totalQuantity >= tier.minQty) {
        return tier;
      }
    }
    return null;
  }

  /// Default tenant platform utama (ekasir.my.id)
  static const TenantModel platformRoot = TenantModel(
    id: 0,
    subdomain: '',
    name: 'eKasir',
    primaryColor: '#2563EB',
    plan: 'enterprise',
    orderNotificationSound: 'dingdong',
  );

  /// Default tenant jika gagal load
  static const TenantModel fallback = platformRoot;
}

class DeliveryDiscountTier {
  final int minQty;
  final int discountAmount;

  const DeliveryDiscountTier({
    required this.minQty,
    required this.discountAmount,
  });

  factory DeliveryDiscountTier.fromJson(Map<String, dynamic> json) {
    return DeliveryDiscountTier(
      minQty: (json['min_qty'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_qty': minQty,
      'discount_amount': discountAmount,
    };
  }
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
