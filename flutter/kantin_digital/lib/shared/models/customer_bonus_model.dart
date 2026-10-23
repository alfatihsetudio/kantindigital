class CustomerBonusModel {
  final int id;
  final String customerPhone;
  final String? customerName;
  final int bonusPercent;
  final bool isActive;
  final String? notes;
  final int totalOrders;
  final int totalSpend;
  final int totalBonusEarned;
  final int totalBonusClaimed;
  final int bonusBalance;
  final DateTime? lastOrderAt;
  final DateTime? createdAt;

  CustomerBonusModel({
    required this.id,
    required this.customerPhone,
    this.customerName,
    this.bonusPercent = 5,
    this.isActive = true,
    this.notes,
    this.totalOrders = 0,
    this.totalSpend = 0,
    this.totalBonusEarned = 0,
    this.totalBonusClaimed = 0,
    this.bonusBalance = 0,
    this.lastOrderAt,
    this.createdAt,
  });

  factory CustomerBonusModel.fromJson(Map<String, dynamic> json) {
    return CustomerBonusModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerPhone: json['customer_phone']?.toString() ?? '',
      customerName: json['customer_name']?.toString(),
      bonusPercent: (json['bonus_percent'] as num?)?.toInt() ?? 5,
      isActive: json['is_active'] == null ||
          json['is_active'] == true ||
          json['is_active'] == 1,
      notes: json['notes']?.toString(),
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalSpend: (json['total_spend'] as num?)?.toInt() ?? 0,
      totalBonusEarned: (json['total_bonus_earned'] as num?)?.toInt() ?? 0,
      totalBonusClaimed: (json['total_bonus_claimed'] as num?)?.toInt() ?? 0,
      bonusBalance: (json['bonus_balance'] as num?)?.toInt() ?? 0,
      lastOrderAt: json['last_order_at'] != null
          ? DateTime.tryParse(json['last_order_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class CustomerBonusLogModel {
  final int id;
  final int customerBonusId;
  final String customerPhone;
  final int? orderId;
  final String? orderCode;
  final String type; // 'earn', 'claim', 'cancel'
  final int transactionAmount;
  final int bonusPercent;
  final int bonusAmount;
  final int balanceAfter;
  final String? notes;
  final String? staffName;
  final DateTime? createdAt;

  CustomerBonusLogModel({
    required this.id,
    required this.customerBonusId,
    required this.customerPhone,
    this.orderId,
    this.orderCode,
    required this.type,
    this.transactionAmount = 0,
    this.bonusPercent = 0,
    this.bonusAmount = 0,
    this.balanceAfter = 0,
    this.notes,
    this.staffName,
    this.createdAt,
  });

  factory CustomerBonusLogModel.fromJson(Map<String, dynamic> json) {
    return CustomerBonusLogModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerBonusId: (json['customer_bonus_id'] as num?)?.toInt() ?? 0,
      customerPhone: json['customer_phone']?.toString() ?? '',
      orderId: (json['order_id'] as num?)?.toInt(),
      orderCode: json['order_code']?.toString(),
      type: json['type']?.toString() ?? 'earn',
      transactionAmount: (json['transaction_amount'] as num?)?.toInt() ?? 0,
      bonusPercent: (json['bonus_percent'] as num?)?.toInt() ?? 0,
      bonusAmount: (json['bonus_amount'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toInt() ?? 0,
      notes: json['notes']?.toString(),
      staffName: json['user']?['name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class CustomerBonusSummary {
  final int totalCustomers;
  final int totalSpend;
  final int totalBonusEarned;
  final int totalBonusClaimed;
  final int totalBonusBalance;

  CustomerBonusSummary({
    this.totalCustomers = 0,
    this.totalSpend = 0,
    this.totalBonusEarned = 0,
    this.totalBonusClaimed = 0,
    this.totalBonusBalance = 0,
  });

  factory CustomerBonusSummary.fromJson(Map<String, dynamic> json) {
    return CustomerBonusSummary(
      totalCustomers: (json['total_customers'] as num?)?.toInt() ?? 0,
      totalSpend: (json['total_spend'] as num?)?.toInt() ?? 0,
      totalBonusEarned: (json['total_bonus_earned'] as num?)?.toInt() ?? 0,
      totalBonusClaimed: (json['total_bonus_claimed'] as num?)?.toInt() ?? 0,
      totalBonusBalance: (json['total_bonus_balance'] as num?)?.toInt() ?? 0,
    );
  }
}
