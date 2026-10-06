class CashierOrderModel {
  final int id;
  final String code;
  final String? customerName;
  final String? customerPhone;
  final String status;
  final int totalAmount;
  final int discountAmount;
  final String tableCode;
  final String orderType;
  final String? deliveryAddress;
  final String createdAt;
  final List<CashierOrderItem> items;

  CashierOrderModel({
    required this.id,
    required this.code,
    this.customerName,
    this.customerPhone,
    required this.status,
    required this.totalAmount,
    this.discountAmount = 0,
    required this.tableCode,
    required this.orderType,
    this.deliveryAddress,
    required this.createdAt,
    required this.items,
  });

  factory CashierOrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?) ?? [];
    return CashierOrderModel(
      id: json['id'] as int,
      code: json['code'] as String,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      status: json['status'] as String,
      totalAmount: (json['total_amount'] as num).toInt(),
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
      tableCode: json['table']?['code'] ?? '-',
      orderType: (json['order_type'] ?? 'dine_in').toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      createdAt: json['created_at'] as String,
      items: itemsList.map((e) => CashierOrderItem.fromJson(e)).toList(),
    );
  }

  String get fulfillmentLabel => switch (orderType) {
    'delivery' => 'Pengantaran',
    'pickup' => 'Ambil sendiri',
    _ => 'Meja $tableCode',
  };
}

class CashierOrderItem {
  final String menuName;
  final int quantity;
  final int price;
  final List<CashierOrderTopping> toppings;
  final String? notes;

  CashierOrderItem({
    required this.menuName,
    required this.quantity,
    required this.price,
    required this.toppings,
    this.notes,
  });

  factory CashierOrderItem.fromJson(Map<String, dynamic> json) {
    final toppingsList = (json['toppings'] as List?) ?? [];
    return CashierOrderItem(
      menuName: json['menu_name'] as String,
      quantity: json['quantity'] as int,
      price: json['price'] as int,
      toppings: toppingsList
          .map((e) => CashierOrderTopping.fromJson(e))
          .toList(),
      notes: json['notes']?.toString(),
    );
  }
}

class CashierOrderTopping {
  final String toppingName;
  final int toppingPrice;
  final int quantity;

  CashierOrderTopping({
    required this.toppingName,
    required this.toppingPrice,
    this.quantity = 1,
  });

  factory CashierOrderTopping.fromJson(Map<String, dynamic> json) {
    return CashierOrderTopping(
      toppingName: json['topping_name'] as String,
      toppingPrice: json['topping_price'] as int,
      quantity: (json['quantity'] as int?) ?? 1,
    );
  }
}
