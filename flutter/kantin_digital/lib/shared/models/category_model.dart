class CategoryModel {
  final int id;
  final String name;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  CategoryModel copyWith({int? id, String? name, bool? isActive}) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }
}
