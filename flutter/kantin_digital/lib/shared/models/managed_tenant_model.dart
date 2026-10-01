class ManagedTenantModel {
  const ManagedTenantModel({
    required this.id,
    required this.subdomain,
    required this.name,
    required this.plan,
    required this.isActive,
    this.expiresAt,
    this.primaryColor,
    this.address,
    this.phone,
    this.whatsapp,
    this.usersCount = 0,
    this.menusCount = 0,
    this.ordersCount = 0,
  });

  final int id;
  final String subdomain;
  final String name;
  final String plan;
  final bool isActive;
  final String? expiresAt;
  final String? primaryColor;
  final String? address;
  final String? phone;
  final String? whatsapp;
  final int usersCount;
  final int menusCount;
  final int ordersCount;

  bool get isExpired {
    final expiry = expiresAt == null ? null : DateTime.tryParse(expiresAt!);
    return expiry != null && !expiry.isAfter(DateTime.now());
  }

  factory ManagedTenantModel.fromJson(Map<String, dynamic> json) {
    return ManagedTenantModel(
      id: (json['id'] as num).toInt(),
      subdomain: (json['subdomain'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      plan: (json['plan'] ?? 'free').toString(),
      isActive: _asBool(json['is_active']),
      expiresAt: json['expires_at']?.toString(),
      primaryColor: json['primary_color']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      whatsapp: json['whatsapp']?.toString(),
      usersCount: _asInt(json['users_count']),
      menusCount: _asInt(json['menus_count']),
      ordersCount: _asInt(json['orders_count']),
    );
  }

  static bool _asBool(dynamic value) =>
      value == true || value == 1 || value == '1' || value == 'true';

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}
