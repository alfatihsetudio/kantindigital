enum OrderStatus {
  unpaid,
  paid,
  processing,
  ready,
  served,
  cancelled,
}

extension OrderStatusX on OrderStatus {
  static OrderStatus fromApi(String value) {
    switch (value.toUpperCase()) {
      case 'UNPAID':
        return OrderStatus.unpaid;
      case 'PAID':
        return OrderStatus.paid;
      case 'PROCESSING':
        return OrderStatus.processing;
      case 'READY':
        return OrderStatus.ready;
      case 'SERVED':
        return OrderStatus.served;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.unpaid;
    }
  }

  String toApi() => name.toUpperCase();
}

