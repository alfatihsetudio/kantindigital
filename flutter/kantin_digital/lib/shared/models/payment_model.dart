import '../constants/payment_method.dart';

class PaymentModel {
  final int id;
  final PaymentMethod method;
  final int amount;
  final String? providerRef;

  const PaymentModel({
    required this.id,
    required this.method,
    required this.amount,
    this.providerRef,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] as num).toInt(),
      method: PaymentMethodX.fromApi((json['method'] ?? 'QRIS').toString()),
      amount: (json['amount'] as num).toInt(),
      providerRef: json['provider_ref']?.toString(),
    );
  }
}

