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
  final String paymentMethod;
  final String? qrisPayload;
  final String? merchantName;
  final String? merchantCity;
  final String? whatsappNumber;
  final String orderType;
  final String? deliveryAddress;
  final TableModel? table;
  final int totalAmount;
  final List<OrderItemModel> items;
  final PaymentModel? payment;

  const OrderModel({
    required this.id,
    required this.code,
    this.customerName,
    this.customerPhone,
    required this.status,
    this.paymentMethod = 'qris',
    this.qrisPayload,
    this.merchantName,
    this.merchantCity,
    this.whatsappNumber,
    required this.orderType,
    this.deliveryAddress,
    required this.table,
    required this.totalAmount,
    required this.items,
    this.payment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final qrisMap = json['qris'] is Map ? json['qris'] as Map : null;
    final rawTable = json['table'];
    final rawOrderType = json['order_type']?.toString();

    return OrderModel(
      id: (json['id'] as num).toInt(),
      code: (json['code'] ?? '').toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      status: OrderStatusX.fromApi((json['status'] ?? 'UNPAID').toString()),
      paymentMethod: (json['payment_method'] ?? 'qris').toString(),
      qrisPayload: qrisMap?['payload']?.toString(),
      merchantName: qrisMap?['merchant_name']?.toString() ?? 'KANTIN DIGITAL',
      merchantCity: qrisMap?['merchant_city']?.toString() ?? 'SERANG',
      whatsappNumber: qrisMap?['whatsapp_number']?.toString() ?? '087771262100',
      orderType: rawOrderType ?? (rawTable == null ? 'pickup' : 'dine_in'),
      deliveryAddress: json['delivery_address']?.toString(),
      table: rawTable is Map<String, dynamic>
          ? TableModel.fromJson(rawTable)
          : null,
      totalAmount: (json['total_amount'] as num).toInt(),
      items: rawItems is List
          ? rawItems
                .map((e) => OrderItemModel.fromJson(e as Map<String, dynamic>))
                .toList()
          : const [],
      payment: json['payment'] is Map<String, dynamic>
          ? PaymentModel.fromJson(json['payment'] as Map<String, dynamic>)
          : null,
    );
  }
}
