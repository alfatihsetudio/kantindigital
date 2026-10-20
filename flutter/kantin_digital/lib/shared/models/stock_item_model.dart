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
    return StockItemModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'gram',
      category: json['category'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      todayPurchasedQty: (json['today_purchased_qty'] as num?)?.toDouble() ?? 0.0,
      todayPurchasedAmount: (json['today_purchased_amount'] as num?)?.toDouble() ?? 0.0,
      todayPurchasedCount: (json['today_purchased_count'] as num?)?.toInt() ?? 0,
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

