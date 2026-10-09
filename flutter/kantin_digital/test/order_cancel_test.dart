import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/features/customer/order_status/order_status_controller.dart';
import 'package:kantin_digital/shared/constants/order_status.dart';
import 'package:kantin_digital/shared/services/demo_session_manager.dart';

void main() {
  setUp(() {
    DemoSessionManager.enableDemoMode();
  });

  tearDown(() {
    DemoSessionManager.disableDemoMode();
  });

  test('DemoSessionManager can cancel order by code', () {
    final order = DemoSessionManager.getCashierOrders().first;
    DemoSessionManager.cancelOrderByCode(order.code);

    final cancelledOrder = DemoSessionManager.getOrderByCode(order.code);
    expect(cancelledOrder, isNotNull);
    expect(cancelledOrder!.status, equals(OrderStatus.cancelled));
  });

  test('OrderStatusController cancelOrder returns cancelled status in demo mode', () async {
    final controller = OrderStatusController();
    final order = DemoSessionManager.getCashierOrders().first;

    final updated = await controller.cancelOrder(order.code);
    expect(updated.status, equals(OrderStatus.cancelled));
  });
}
