import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/config/api_config.dart';

class TenantModel {
  final int id;
  final String subdomain;
  final String name;
  final String? logoUrl;
  final String primaryColor;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final String plan;
  final bool isActive;
  final String? metaTitle;
  final String? metaDescription;

  const TenantModel({
    required this.id,
    required this.subdomain,
    required this.name,
    this.logoUrl,
    this.primaryColor = '#00AA13',
    this.address,
    this.phone,
    this.whatsapp,
    this.plan = 'free',
    this.isActive = true,
    this.metaTitle,
    this.metaDescription,
  });

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
      plan: json['plan']?.toString() ?? 'free',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      metaTitle: json['meta_title']?.toString(),
      metaDescription: json['meta_description']?.toString(),
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
      'plan': plan,
      'is_active': isActive,
      'meta_title': metaTitle,
      'meta_description': metaDescription,
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
