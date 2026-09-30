import 'order_item_topping_model.dart';

class OrderItemModel {
  final int id;
  final int menuId;
  final String menuName;
  final int price;
  final int quantity;
  final List<OrderItemToppingModel> toppings;
  final String? notes;

  const OrderItemModel({
    required this.id,
    required this.menuId,
    required this.menuName,
    required this.price,
    required this.quantity,
    required this.toppings,
    this.notes,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final rawToppings = json['toppings'];
    return OrderItemModel(
      id: (json['id'] as num).toInt(),
      menuId: (json['menu_id'] as num).toInt(),
      menuName: (json['menu_name'] ?? '').toString(),
      price: (json['price'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
      toppings: rawToppings is List
          ? rawToppings.map((e) => OrderItemToppingModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      notes: json['notes']?.toString(),
    );
  }
}

