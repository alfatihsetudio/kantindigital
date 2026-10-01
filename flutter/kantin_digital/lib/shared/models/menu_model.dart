class MenuModel {
  final int id;
  final String name;
  final String categoryName;
  final int price;
  final String? imageUrl;
  final String? description;
  final bool isAvailable;

  const MenuModel({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.price,
    this.imageUrl,
    this.description,
    this.isAvailable = true,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) {
    return MenuModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? '').toString(),
      price: (json['price'] as num).toInt(),
      imageUrl: json['image_url']?.toString(),
      description: json['description']?.toString(),
      isAvailable: _parseAvailability(json['is_available']),
    );
  }

  static bool _parseAvailability(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return true;
  }
}
