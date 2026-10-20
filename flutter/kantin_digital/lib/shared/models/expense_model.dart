import 'stock_item_model.dart';

/// Model catatan belanja / pengeluaran operasional kantin.
class ExpenseModel {
  final int id;
  final int? userId;
  final String? userName;
  final int? stockItemId;
  final double? quantity;
  final String? unit;
  final StockItemModel? stockItem;
  final String expenseDate;
  final String category;
  final String description;
  final double amount;
  final String? notes;
  final DateTime? createdAt;

  const ExpenseModel({
    required this.id,
    this.userId,
    this.userName,
    this.stockItemId,
    this.quantity,
    this.unit,
    this.stockItem,
    required this.expenseDate,
    required this.category,
    required this.description,
    this.amount = 0,
    this.notes,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final userMap = rawUser is Map<String, dynamic> ? rawUser : null;

    final rawStockItem = json['stock_item'] ?? json['stockItem'];
    final stockItem = rawStockItem is Map<String, dynamic>
        ? StockItemModel.fromJson(rawStockItem)
        : null;

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString())?.toLocal();
    }

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

    return ExpenseModel(
      id: parseInt(json['id']) ?? 0,
      userId: parseInt(json['user_id']),
      userName: userMap?['name']?.toString() ?? json['user_name']?.toString(),
      stockItemId: parseInt(json['stock_item_id']),
      quantity: json['quantity'] != null ? parseDouble(json['quantity']) : null,
      unit: json['unit']?.toString(),
      stockItem: stockItem,
      expenseDate: json['expense_date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Lainnya',
      description: json['description']?.toString() ?? '',
      amount: parseDouble(json['amount']),
      notes: json['notes']?.toString(),
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'stock_item_id': stockItemId,
      'quantity': quantity,
      'unit': unit,
      'stock_item': stockItem?.toJson(),
      'expense_date': expenseDate,
      'category': category,
      'description': description,
      'amount': amount,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// Hasil pemuatan daftar pengeluaran beserta ringkasannya.
class ExpenseListResult {
  final List<ExpenseModel> expenses;
  final double totalAmount;
  final int totalTransactions;

  const ExpenseListResult({
    this.expenses = const [],
    this.totalAmount = 0,
    this.totalTransactions = 0,
  });
}
