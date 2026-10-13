class StockItemModel {
  final int id;
  final String name;
  final String unit;
  final String? category;
  final bool isActive;

  const StockItemModel({
    required this.id,
    required this.name,
    required this.unit,
    this.category,
    this.isActive = true,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    return StockItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'gram',
      category: json['category'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'category': category,
      'is_active': isActive,
    };
  }

  StockItemModel copyWith({
    int? id,
    String? name,
    String? unit,
    String? category,
    bool? isActive,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }
}
