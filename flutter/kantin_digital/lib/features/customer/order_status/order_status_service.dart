import '../../../core/network/api_client.dart';
import '../../../shared/models/order_model.dart';

class OrderStatusService {
  final ApiClient _client = ApiClient();

  /// Ekspektasi endpoint: GET /orders/{code}
  Future<OrderModel> fetchByCode(String code) async {
    final json = await _client.get('/orders/$code') as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }
}

