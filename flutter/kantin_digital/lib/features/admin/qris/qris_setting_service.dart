import '../../../core/network/api_client.dart';
import '../../../shared/models/qris_setting_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class QrisSettingService {
  final ApiClient _client;

  QrisSettingService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<QrisSettingModel> getSetting() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.demoQrisSetting;
    }
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
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.updateQrisSetting(
        merchantName: merchantName,
        merchantCity: merchantCity,
        whatsappNumber: whatsappNumber,
        basePayload: basePayload,
        isActive: isActive,
      );
    }
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
