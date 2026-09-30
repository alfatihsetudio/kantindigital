enum PaymentMethod {
  qris,
  cash,
}

extension PaymentMethodX on PaymentMethod {
  static PaymentMethod fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'QRIS':
        return PaymentMethod.qris;
      case 'CASH':
        return PaymentMethod.cash;
      default:
        return PaymentMethod.qris;
    }
  }

  String toApi() => name.toUpperCase();
}

