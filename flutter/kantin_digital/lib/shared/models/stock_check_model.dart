class StockCheckItemModel {
  final int? id;
  final int? stockCheckId;
  final int? stockItemId;
  final String itemName;
  final String unit;
  final double wholeQuantity; // Utuh saat ini
  final double remainderQuantity; // Sisa / gram saat ini
  final double? previousWholeQuantity; // Utuh saat closing sebelumnya
  final double? previousRemainderQuantity; // Sisa saat closing sebelumnya
  final double differenceWhole;
  final double differenceRemainder;
  final bool isMatched;
  final String? notes;

  const StockCheckItemModel({
    this.id,
    this.stockCheckId,
    this.stockItemId,
    required this.itemName,
    required this.unit,
    this.wholeQuantity = 0,
    this.remainderQuantity = 0,
    this.previousWholeQuantity,
    this.previousRemainderQuantity,
    this.differenceWhole = 0,
    this.differenceRemainder = 0,
    this.isMatched = true,
    this.notes,
  });

  factory StockCheckItemModel.fromJson(Map<String, dynamic> json) {
    return StockCheckItemModel(
      id: json['id'] as int?,
      stockCheckId: json['stock_check_id'] as int?,
      stockItemId: json['stock_item_id'] as int?,
      itemName: json['item_name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'gram',
      wholeQuantity: (json['whole_quantity'] as num?)?.toDouble() ?? 0.0,
      remainderQuantity: (json['remainder_quantity'] as num?)?.toDouble() ?? 0.0,
      previousWholeQuantity: (json['previous_whole_quantity'] as num?)?.toDouble(),
      previousRemainderQuantity: (json['previous_remainder_quantity'] as num?)?.toDouble(),
      differenceWhole: (json['difference_whole'] as num?)?.toDouble() ?? 0.0,
      differenceRemainder: (json['difference_remainder'] as num?)?.toDouble() ?? 0.0,
      isMatched: json['is_matched'] == true || json['is_matched'] == 1,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (stockCheckId != null) 'stock_check_id': stockCheckId,
      if (stockItemId != null) 'stock_item_id': stockItemId,
      'item_name': itemName,
      'unit': unit,
      'whole_quantity': wholeQuantity,
      'remainder_quantity': remainderQuantity,
      if (previousWholeQuantity != null) 'previous_whole_quantity': previousWholeQuantity,
      if (previousRemainderQuantity != null) 'previous_remainder_quantity': previousRemainderQuantity,
      'difference_whole': differenceWhole,
      'difference_remainder': differenceRemainder,
      'is_matched': isMatched,
      if (notes != null) 'notes': notes,
    };
  }
}

class StockCheckModel {
  final int id;
  final int? userId;
  final String? userName;
  final String checkType; // 'closing' atau 'opening'
  final String checkDate;
  final String status; // 'completed' atau 'has_difference'
  final int totalItems;
  final int matchedItems;
  final String? notes;
  final DateTime? createdAt;
  final List<StockCheckItemModel> items;

  const StockCheckModel({
    required this.id,
    this.userId,
    this.userName,
    required this.checkType,
    required this.checkDate,
    required this.status,
    this.totalItems = 0,
    this.matchedItems = 0,
    this.notes,
    this.createdAt,
    this.items = const [],
  });

  bool get isClosing => checkType.toLowerCase() == 'closing';
  bool get isOpening => checkType.toLowerCase() == 'opening';
  bool get hasDifference => status == 'has_difference' || (totalItems > 0 && matchedItems < totalItems);

  factory StockCheckModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userMap = rawUser is Map<String, dynamic> ? rawUser : null;
    final userName = userMap?['name'] as String?;

    final rawItems = json['items'];
    final itemsList = (rawItems is List)
        ? rawItems.map((e) => StockCheckItemModel.fromJson(e as Map<String, dynamic>)).toList()
        : <StockCheckItemModel>[];

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString());
    }

    return StockCheckModel(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int?,
      userName: userName,
      checkType: json['check_type'] as String? ?? 'closing',
      checkDate: json['check_date']?.toString() ?? '',
      status: json['status'] as String? ?? 'completed',
      totalItems: json['total_items'] as int? ?? itemsList.length,
      matchedItems: json['matched_items'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: created,
      items: itemsList,
    );
  }
}
