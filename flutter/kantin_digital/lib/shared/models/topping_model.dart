class ToppingModel {
  final int id;
  final String name;
  final int price;
  final int quantity; // Berapa banyak menu yang dapat toping ini
  final int maxQuantity;
  final List<int> categoryIds;
  final List<String> categoryNames;

  const ToppingModel({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.maxQuantity = 0,
    this.categoryIds = const [],
    this.categoryNames = const [],
  });

  factory ToppingModel.fromJson(Map<String, dynamic> json) {
    return ToppingModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      price: (json['price'] as num).toInt(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      maxQuantity: (json['max'] as num?)?.toInt() ?? 0,
      categoryIds: _parseIntList(json['category_ids']),
      categoryNames: _parseStringList(json['category_names']),
    );
  }

  static List<int> _parseIntList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((id) => int.tryParse(id.toString()))
        .whereType<int>()
        .toSet()
        .toList();
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
