class CashierShiftReportModel {
  final int id;
  final int cashierId;
  final String? cashierName;
  final DateTime? shiftOpenedAt;
  final DateTime? shiftClosedAt;
  final int totalOrders;
  final double totalCashExpected;
  final double totalQrisExpected;
  final double totalSalesExpected;
  final double cashReceived;
  final double cashDifference;
  final String status; // PENDING, APPROVED, REJECTED
  final String? cashierNotes;
  final int? approvedBy;
  final String? approverName;
  final DateTime? approvedAt;
  final String? approvalNotes;
  final DateTime? createdAt;

  const CashierShiftReportModel({
    required this.id,
    required this.cashierId,
    this.cashierName,
    this.shiftOpenedAt,
    this.shiftClosedAt,
    this.totalOrders = 0,
    this.totalCashExpected = 0,
    this.totalQrisExpected = 0,
    this.totalSalesExpected = 0,
    this.cashReceived = 0,
    this.cashDifference = 0,
    this.status = 'PENDING',
    this.cashierNotes,
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    this.approvalNotes,
    this.createdAt,
  });

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';
  bool get isRejected => status.toUpperCase() == 'REJECTED';

  factory CashierShiftReportModel.fromJson(Map<String, dynamic> json) {
    return CashierShiftReportModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      cashierId: (json['cashier_id'] as num?)?.toInt() ?? 0,
      cashierName: json['cashier']?['name']?.toString() ?? json['cashier_name']?.toString(),
      shiftOpenedAt: json['shift_opened_at'] != null ? DateTime.tryParse(json['shift_opened_at'].toString())?.toLocal() : null,
      shiftClosedAt: json['shift_closed_at'] != null ? DateTime.tryParse(json['shift_closed_at'].toString())?.toLocal() : null,
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      totalCashExpected: (json['total_cash_expected'] as num?)?.toDouble() ?? 0.0,
      totalQrisExpected: (json['total_qris_expected'] as num?)?.toDouble() ?? 0.0,
      totalSalesExpected: (json['total_sales_expected'] as num?)?.toDouble() ?? 0.0,
      cashReceived: (json['cash_received'] as num?)?.toDouble() ?? 0.0,
      cashDifference: (json['cash_difference'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      cashierNotes: json['cashier_notes']?.toString(),
      approvedBy: (json['approved_by'] as num?)?.toInt(),
      approverName: json['approver']?['name']?.toString() ?? json['approver_name']?.toString(),
      approvedAt: json['approved_at'] != null ? DateTime.tryParse(json['approved_at'].toString())?.toLocal() : null,
      approvalNotes: json['approval_notes']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString())?.toLocal() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cashier_id': cashierId,
      'cashier_name': cashierName,
      'shift_opened_at': shiftOpenedAt?.toIso8601String(),
      'shift_closed_at': shiftClosedAt?.toIso8601String(),
      'total_orders': totalOrders,
      'total_cash_expected': totalCashExpected,
      'total_qris_expected': totalQrisExpected,
      'total_sales_expected': totalSalesExpected,
      'cash_received': cashReceived,
      'cash_difference': cashDifference,
      'status': status,
      'cashier_notes': cashierNotes,
      'approved_by': approvedBy,
      'approver_name': approverName,
      'approved_at': approvedAt?.toIso8601String(),
      'approval_notes': approvalNotes,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

class CurrentShiftData {
  final bool isStoreOpen;
  final String? storeOpenedAt;
  final int totalOrders;
  final int cashOrdersCount;
  final int qrisOrdersCount;
  final double totalCashExpected;
  final double totalQrisExpected;
  final double totalSalesExpected;
  final int unpaidOrdersCount;
  final double unpaidAmount;
  final CashierShiftReportModel? pendingReport;
  final List<CashierShiftReportModel> recentReports;

  const CurrentShiftData({
    this.isStoreOpen = false,
    this.storeOpenedAt,
    this.totalOrders = 0,
    this.cashOrdersCount = 0,
    this.qrisOrdersCount = 0,
    this.totalCashExpected = 0,
    this.totalQrisExpected = 0,
    this.totalSalesExpected = 0,
    this.unpaidOrdersCount = 0,
    this.unpaidAmount = 0,
    this.pendingReport,
    this.recentReports = const [],
  });

  factory CurrentShiftData.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recent_reports'] as List? ?? [];
    return CurrentShiftData(
      isStoreOpen: json['is_store_open'] == true,
      storeOpenedAt: json['store_opened_at']?.toString(),
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      cashOrdersCount: (json['cash_orders_count'] as num?)?.toInt() ?? 0,
      qrisOrdersCount: (json['qris_orders_count'] as num?)?.toInt() ?? 0,
      totalCashExpected: (json['total_cash_expected'] as num?)?.toDouble() ?? 0.0,
      totalQrisExpected: (json['total_qris_expected'] as num?)?.toDouble() ?? 0.0,
      totalSalesExpected: (json['total_sales_expected'] as num?)?.toDouble() ?? 0.0,
      unpaidOrdersCount: (json['unpaid_orders_count'] as num?)?.toInt() ?? 0,
      unpaidAmount: (json['unpaid_amount'] as num?)?.toDouble() ?? 0.0,
      pendingReport: json['pending_report'] != null
          ? CashierShiftReportModel.fromJson(json['pending_report'] as Map<String, dynamic>)
          : null,
      recentReports: recentRaw
          .whereType<Map<String, dynamic>>()
          .map((r) => CashierShiftReportModel.fromJson(r))
          .toList(),
    );
  }
}
