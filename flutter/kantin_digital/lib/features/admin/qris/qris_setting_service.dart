import '../../../core/network/api_client.dart';
import '../../../shared/models/qris_setting_model.dart';

class QrisSettingService {
  final ApiClient _client;

  QrisSettingService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<QrisSettingModel> getSetting() async {
    final response = await _client.get('/qris-setting') as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>;
    return QrisSettingModel.fromJson(data);
  }

  Future<QrisSettingModel> updateSetting({
    required String merchantName,
    required String merchantCity,
    required String whatsappNumber,
    required String basePayload,
    bool isActive = true,
  }) async {
    final response = await _client.post(
      '/qris-setting',
      body: {
        'merchant_name': merchantName,
        'merchant_city': merchantCity,
        'whatsapp_number': whatsappNumber,
        'base_payload': basePayload,
        'is_active': isActive,
      },
    ) as Map<String, dynamic>;
    final data = response['data'] as Map<String, dynamic>;
    return QrisSettingModel.fromJson(data);
  }
}
