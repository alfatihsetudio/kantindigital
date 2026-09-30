class QrisSettingModel {
  final int id;
  final String merchantName;
  final String merchantCity;
  final String whatsappNumber;
  final String basePayload;
  final bool isActive;

  const QrisSettingModel({
    required this.id,
    required this.merchantName,
    required this.merchantCity,
    this.whatsappNumber = '087771262100',
    required this.basePayload,
    this.isActive = true,
  });

  factory QrisSettingModel.fromJson(Map<String, dynamic> json) {
    return QrisSettingModel(
      id: (json['id'] as num?)?.toInt() ?? 1,
      merchantName: (json['merchant_name'] ?? 'KANTIN DIGITAL').toString(),
      merchantCity: (json['merchant_city'] ?? 'SERANG').toString(),
      whatsappNumber: (json['whatsapp_number'] ?? '087771262100').toString(),
      basePayload: (json['base_payload'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant_name': merchantName,
      'merchant_city': merchantCity,
      'whatsapp_number': whatsappNumber,
      'base_payload': basePayload,
      'is_active': isActive,
    };
  }
}
