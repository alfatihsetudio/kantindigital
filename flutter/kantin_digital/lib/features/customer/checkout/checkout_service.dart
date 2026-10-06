import '../../../core/network/api_client.dart';
import '../../../shared/models/cart_item_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class CheckoutService {
  final ApiClient _client;

  CheckoutService(this._client);

  Future<String> createOrder({
    String? tableCode,
    required String orderType,
    String? deliveryAddress,
    required List<CartItemModel> items,
    required String customerName,
    required String customerPhone,
    String paymentMethod = 'qris',
  }) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.createDemoOrder(
        tableCode: tableCode,
        orderType: orderType,
        deliveryAddress: deliveryAddress,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        paymentMethod: paymentMethod,
      );
    }
    final body = {
      if (tableCode != null) 'table_code': tableCode,
      'order_type': orderType,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
      'items': items
          .map(
            (e) => {
              'menu_id': e.menu.id,
              'quantity': e.quantity,
              'toppings': e.toppings
                  .map(
                    (topping) => {
                      'topping_id': topping.id,
                      'quantity': topping.quantity,
                    },
                  )
                  .toList(),
              'notes': e.notes,
            },
          )
          .toList(),
    };

    final json =
        await _client.post('/orders', body: body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    // order_code bisa berupa kode unik untuk tracking
    return (data['code'] ?? '').toString();
  }
}
