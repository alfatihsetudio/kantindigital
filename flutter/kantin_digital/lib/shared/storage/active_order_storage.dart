import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple storage for active order tracking
class ActiveOrderStorage extends ChangeNotifier {
  ActiveOrderStorage._();
  static final ActiveOrderStorage instance = ActiveOrderStorage._();

  String? _orderCode;
  String? get orderCode => _orderCode;

  bool get hasActiveOrder => _orderCode != null && _orderCode!.isNotEmpty;

  static const _key = 'active_order_code';

  /// Load order code from persistent storage
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _orderCode = prefs.getString(_key);
      notifyListeners();
    } catch (e) {
      debugPrint('ActiveOrderStorage.load error: $e');
      // Fail silently, just use null
      _orderCode = null;
    }
  }

  /// Save order code
  Future<void> setOrderCode(String code) async {
    _orderCode = code;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, code);
    } catch (e) {
      debugPrint('ActiveOrderStorage.setOrderCode error: $e');
    }
  }

  /// Clear order code (when order is completed/served)
  Future<void> clear() async {
    _orderCode = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('ActiveOrderStorage.clear error: $e');
    }
  }
}
