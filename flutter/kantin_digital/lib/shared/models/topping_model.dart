class ToppingModel {
  final int id;
  final String name;
  final int price;
  final int quantity; // Berapa banyak menu yang dapat toping ini

  const ToppingModel({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  factory ToppingModel.fromJson(Map<String, dynamic> json) {
    return ToppingModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

