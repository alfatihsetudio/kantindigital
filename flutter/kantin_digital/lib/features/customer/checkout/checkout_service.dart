import '../../../core/network/api_client.dart';
import '../../../shared/models/cart_item_model.dart';

class CheckoutService {
  final ApiClient _client;

  CheckoutService(this._client);

  /// Memanggil endpoint pembuatan order.
  /// Ekspektasi endpoint Laravel: POST /orders
  /// Body kira-kira:
  /// {
  ///   "order_type": "delivery",
  ///   "delivery_address": "Jl. Merdeka No. 10",
  ///   "customer_name": "John Doe",
  ///   "customer_phone": "081234567890",
  ///   "items": [
  ///     { "menu_id": 1, "quantity": 2, "topping_ids": [1,2], "notes": "..." }
  ///   ]
  /// }
  Future<String> createOrder({
    String? tableCode,
    required String orderType,
    String? deliveryAddress,
    required List<CartItemModel> items,
    required String customerName,
    required String customerPhone,
    String paymentMethod = 'qris',
  }) async {
    final body = {
      if (tableCode != null) 'table_code': tableCode,
      'order_type': orderType,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'payment_method': paymentMethod,
      'items': items
          .map((e) => {
                'menu_id': e.menu.id,
                'quantity': e.quantity,
                'topping_ids': e.toppings.map((t) => t.id).toList(),
                'notes': e.notes,
              })
          .toList(),
    };

    final json = await _client.post('/orders', body: body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    // order_code bisa berupa kode unik untuk tracking
    return (data['code'] ?? '').toString();
  }
}

