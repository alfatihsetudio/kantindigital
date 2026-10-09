import '../../../shared/models/order_model.dart';
import 'order_status_service.dart';

class OrderStatusController {
  final OrderStatusService _service = OrderStatusService();

  Future<OrderModel> fetchByCode(String code) => _service.fetchByCode(code);
  Future<OrderModel> cancelOrder(String code) => _service.cancelOrder(code);
}

