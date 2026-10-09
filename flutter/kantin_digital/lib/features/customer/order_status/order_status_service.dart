import '../../../core/network/api_client.dart';
import '../../../shared/models/order_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class OrderStatusService {
  final ApiClient _client = ApiClient();

  /// Ekspektasi endpoint: GET /orders/{code}
  Future<OrderModel> fetchByCode(String code) async {
    if (code.startsWith('DEMO-') || DemoSessionManager.isDemoMode) {
      final demoOrder = DemoSessionManager.getOrderByCode(code);
      if (demoOrder != null) return demoOrder;
    }

    final json = await _client.get('/orders/$code') as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }

  /// Batalkan pesanan customer: POST /orders/{code}/cancel
  Future<OrderModel> cancelOrder(String code) async {
    if (code.startsWith('DEMO-') || DemoSessionManager.isDemoMode) {
      DemoSessionManager.cancelOrderByCode(code);
      final demoOrder = DemoSessionManager.getOrderByCode(code);
      if (demoOrder != null) return demoOrder;
    }

    await _client.post('/orders/$code/cancel');
    return fetchByCode(code);
  }
}

