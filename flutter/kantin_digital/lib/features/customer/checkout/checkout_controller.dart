import '../cart/cart_controller.dart';
import '../../../shared/models/cart_item_model.dart';
import 'checkout_service.dart';
import '../../../core/network/api_client.dart';

class CheckoutResult {
  final String? orderCode;
  final String? error;

  CheckoutResult.success(this.orderCode) : error = null;
  CheckoutResult.error(this.error) : orderCode = null;
}

class CheckoutController {
  final CheckoutService _service = CheckoutService(ApiClient());

  Future<CheckoutResult> createOrder({
    required String tableCode,
    required String customerName,
    required String customerPhone,
    String paymentMethod = 'qris',
  }) async {
    try {
      final List<CartItemModel> items = CartController.instance.items;
      final code = await _service.createOrder(
        tableCode: tableCode,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
      );
      return CheckoutResult.success(code);
    } catch (e) {
      return CheckoutResult.error(e.toString());
    }
  }
}

