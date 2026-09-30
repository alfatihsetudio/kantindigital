class OrderItemToppingModel {
  final int id;
  final int toppingId;
  final String toppingName;
  final int toppingPrice;
  final int quantity; // Berapa banyak menu yang dapat toping ini

  const OrderItemToppingModel({
    required this.id,
    required this.toppingId,
    required this.toppingName,
    required this.toppingPrice,
    this.quantity = 1,
  });

  factory OrderItemToppingModel.fromJson(Map<String, dynamic> json) {
    return OrderItemToppingModel(
      id: (json['id'] as num).toInt(),
      toppingId: (json['topping_id'] as num).toInt(),
      toppingName: (json['topping_name'] ?? '').toString(),
      toppingPrice: (json['topping_price'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

