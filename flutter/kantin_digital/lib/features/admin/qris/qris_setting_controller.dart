import '../../../shared/models/qris_setting_model.dart';
import 'qris_setting_service.dart';

class QrisSettingController {
  final QrisSettingService _service = QrisSettingService();

  Future<QrisSettingModel> fetchSetting() {
    return _service.getSetting();
  }

  Future<QrisSettingModel> saveSetting({
    required String merchantName,
    required String merchantCity,
    required String whatsappNumber,
    required String basePayload,
    bool isActive = true,
  }) {
    return _service.updateSetting(
      merchantName: merchantName,
      merchantCity: merchantCity,
      whatsappNumber: whatsappNumber,
      basePayload: basePayload,
      isActive: isActive,
    );
  }
}
