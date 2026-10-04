import '../cart/cart_controller.dart';
import '../../../shared/models/cart_item_model.dart';
import '../../../core/network/api_exception.dart';
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
    String? tableCode,
    required String orderType,
    String? deliveryAddress,
    required String customerName,
    required String customerPhone,
    String paymentMethod = 'qris',
  }) async {
    try {
      final List<CartItemModel> items = CartController.instance.items;
      final code = await _service.createOrder(
        tableCode: tableCode,
        orderType: orderType,
        deliveryAddress: deliveryAddress,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
      );
      return CheckoutResult.success(code);
    } on ApiException catch (e) {
      return CheckoutResult.error(e.userMessage);
    } catch (e) {
      return CheckoutResult.error(e.toString());
    }
  }
}
