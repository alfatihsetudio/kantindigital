class MenuToppingModel {
  final int id;
  final int menuId;
  final int toppingId;
  final int min;
  final int max;

  const MenuToppingModel({
    required this.id,
    required this.menuId,
    required this.toppingId,
    required this.min,
    required this.max,
  });

  factory MenuToppingModel.fromJson(Map<String, dynamic> json) {
    return MenuToppingModel(
      id: (json['id'] as num).toInt(),
      menuId: (json['menu_id'] as num).toInt(),
      toppingId: (json['topping_id'] as num).toInt(),
      min: (json['min'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 0,
    );
  }
}

