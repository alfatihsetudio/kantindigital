import 'package:flutter/material.dart';

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
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: (json['id'] as num).toInt(),
      subdomain: json['subdomain']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Kantin Digital',
      logoUrl: json['logo_url']?.toString(),
      primaryColor: json['primary_color']?.toString() ?? '#00AA13',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      plan: json['plan']?.toString() ?? 'free',
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
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
