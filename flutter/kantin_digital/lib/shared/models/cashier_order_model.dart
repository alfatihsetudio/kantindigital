class CashierOrderModel {
  final int id;
  final String code;
  final String? customerName;
  final String? customerPhone;
  final String status;
  final int totalAmount;
  final int discountAmount;
  final int deliveryDiscountAmount;
  final String tableCode;
  final String orderType;
  final String? deliveryAddress;
  final String createdAt;
  final String paymentMethod;
  final List<CashierOrderItem> items;
  final int? cashierShiftReportId;

  CashierOrderModel({
    required this.id,
    required this.code,
    this.customerName,
    this.customerPhone,
    required this.status,
    required this.totalAmount,
    this.discountAmount = 0,
    this.deliveryDiscountAmount = 0,
    required this.tableCode,
    required this.orderType,
    this.deliveryAddress,
    required this.createdAt,
    this.paymentMethod = 'qris',
    required this.items,
    this.cashierShiftReportId,
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
      deliveryDiscountAmount:
          (json['delivery_discount_amount'] as num?)?.toInt() ?? 0,
      tableCode: json['table']?['code'] ?? '-',
      orderType: (json['order_type'] ?? 'dine_in').toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      createdAt: json['created_at'] as String,
      paymentMethod: (json['payment_method'] ?? 'qris').toString(),
      items: itemsList.map((e) => CashierOrderItem.fromJson(e)).toList(),
      cashierShiftReportId: (json['cashier_shift_report_id'] as num?)?.toInt(),
    );
  }

  String get fulfillmentLabel => switch (orderType) {
    'delivery' => 'Pengantaran',
    'pickup' => 'Ambil sendiri',
    _ => 'Meja $tableCode',
  };

  String get paymentMethodLabel => switch (paymentMethod.toLowerCase()) {
    'cash' => 'Tunai',
    'qris' => 'QRIS',
    _ => paymentMethod.toUpperCase(),
  };

  bool get isQris => paymentMethod.toLowerCase() == 'qris';
  bool get isUnsettled => cashierShiftReportId == null;
  bool get isSettled => cashierShiftReportId != null;

  bool get isToday {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }
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
