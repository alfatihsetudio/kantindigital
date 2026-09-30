import '../constants/order_status.dart';
import 'order_item_model.dart';
import 'payment_model.dart';
import 'table_model.dart';

class OrderModel {
  final int id;
  final String code;
  final String? customerName;
  final String? customerPhone;
  final OrderStatus status;
  final TableModel table;
  final int totalAmount;
  final List<OrderItemModel> items;
  final PaymentModel? payment;

  const OrderModel({
    required this.id,
    required this.code,
    this.customerName,
    this.customerPhone,
    required this.status,
    required this.table,
    required this.totalAmount,
    required this.items,
    this.payment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return OrderModel(
      id: (json['id'] as num).toInt(),
      code: (json['code'] ?? '').toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      status: OrderStatusX.fromApi((json['status'] ?? 'UNPAID').toString()),
      table: TableModel.fromJson(json['table'] as Map<String, dynamic>),
      totalAmount: (json['total_amount'] as num).toInt(),
      items: rawItems is List
          ? rawItems.map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>)).toList()
          : const [],
      payment: json['payment'] is Map<String, dynamic> ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>) : null,
    );
  }
}

