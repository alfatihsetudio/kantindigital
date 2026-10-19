/// Model catatan belanja / pengeluaran operasional kantin.
class ExpenseModel {
  final int id;
  final int? userId;
  final String? userName;
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

    DateTime? created;
    if (json['created_at'] != null) {
      created = DateTime.tryParse(json['created_at'].toString())?.toLocal();
    }

    return ExpenseModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt(),
      userName: userMap?['name']?.toString() ?? json['user_name']?.toString(),
      expenseDate: json['expense_date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Lainnya',
      description: json['description']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString(),
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
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
