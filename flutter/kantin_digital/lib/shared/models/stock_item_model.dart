class StockItemModel {
  final int id;
  final String name;
  final String unit;
  final String? category;
  final bool isActive;
  final double todayPurchasedQty;
  final double todayPurchasedAmount;
  final int todayPurchasedCount;

  const StockItemModel({
    required this.id,
    required this.name,
    required this.unit,
    this.category,
    this.isActive = true,
    this.todayPurchasedQty = 0,
    this.todayPurchasedAmount = 0,
    this.todayPurchasedCount = 0,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? defaultValue;
    }

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return StockItemModel(
      id: parseInt(json['id']) ?? 0,
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'gram',
      category: json['category'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      todayPurchasedQty: parseDouble(json['today_purchased_qty']),
      todayPurchasedAmount: parseDouble(json['today_purchased_amount']),
      todayPurchasedCount: parseInt(json['today_purchased_count']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'category': category,
      'is_active': isActive,
      'today_purchased_qty': todayPurchasedQty,
      'today_purchased_amount': todayPurchasedAmount,
      'today_purchased_count': todayPurchasedCount,
    };
  }

  StockItemModel copyWith({
    int? id,
    String? name,
    String? unit,
    String? category,
    bool? isActive,
    double? todayPurchasedQty,
    double? todayPurchasedAmount,
    int? todayPurchasedCount,
  }) {
    return StockItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      todayPurchasedQty: todayPurchasedQty ?? this.todayPurchasedQty,
      todayPurchasedAmount: todayPurchasedAmount ?? this.todayPurchasedAmount,
      todayPurchasedCount: todayPurchasedCount ?? this.todayPurchasedCount,
    );
  }
}

