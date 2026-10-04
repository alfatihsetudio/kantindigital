import '../../../core/network/api_client.dart';
import '../../../shared/models/cashier_order_model.dart';
import '../../../shared/services/demo_session_manager.dart';

export '../../../shared/models/cashier_order_model.dart';

class CashierOrdersService {
  final ApiClient _client = ApiClient();

  Future<List<CashierOrderModel>> getOrders({String? status}) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getCashierOrders(status: status);
    }

    String path = '/cashier/orders';
    if (status != null) {
      path += '?status=$status';
    }
    final response = await _client.get(path);
    final data = response['data'] as List;
    return data.map((json) => CashierOrderModel.fromJson(json)).toList();
  }

  Future<void> updateOrderStatus(int orderId, String newStatus) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.updateOrderStatus(orderId, newStatus);
      return;
    }

    await _client.post('/orders/$orderId/status', body: {'status': newStatus});
  }
}
