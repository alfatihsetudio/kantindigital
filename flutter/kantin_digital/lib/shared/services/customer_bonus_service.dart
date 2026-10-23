import '../../../core/network/api_client.dart';
import '../models/customer_bonus_model.dart';
import 'demo_session_manager.dart';

class CustomerBonusService {
  final ApiClient _client = ApiClient();

  /// Public check for customer's phone bonus & program status
  Future<Map<String, dynamic>?> checkPhoneBonus(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return null;

    if (DemoSessionManager.isDemoMode) {
      return {
        'is_active': true,
        'bonus_percent': 5,
        'min_spend': 0,
        'phone': clean,
        'bonus': {
          'id': 1,
          'customer_name': 'Pelanggan Demo',
          'customer_phone': clean,
          'total_orders': 3,
          'total_spend': 150000,
          'total_bonus_earned': 7500,
          'total_bonus_claimed': 0,
          'bonus_balance': 7500,
        },
      };
    }

    try {
      final res = await _client.get('/customer-bonus/check?phone=$clean');
      if (res is Map<String, dynamic> && res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  /// Get list of customer bonuses with summary (Admin, Cashier, Manager)
  Future<Map<String, dynamic>> getBonuses({
    String? search,
    bool withBalanceOnly = false,
    int page = 1,
  }) async {
    if (DemoSessionManager.isDemoMode) {
      final demoList = [
        CustomerBonusModel(
          id: 1,
          customerPhone: '081234567890',
          customerName: 'Budi Santoso',
          totalOrders: 6,
          totalSpend: 185000,
          totalBonusEarned: 9250,
          totalBonusClaimed: 0,
          bonusBalance: 9250,
          lastOrderAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        CustomerBonusModel(
          id: 2,
          customerPhone: '085712349988',
          customerName: 'Siti Rahma',
          totalOrders: 12,
          totalSpend: 420000,
          totalBonusEarned: 21000,
          totalBonusClaimed: 10000,
          bonusBalance: 11000,
          lastOrderAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      return {
        'summary': CustomerBonusSummary(
          totalCustomers: 2,
          totalSpend: 605000,
          totalBonusEarned: 30250,
          totalBonusClaimed: 10000,
          totalBonusBalance: 20250,
        ),
        'bonuses': demoList,
        'total': 2,
      };
    }

    String path = '/customer-bonuses?page=$page';
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (withBalanceOnly) {
      path += '&with_balance_only=1';
    }

    final res = await _client.get(path) as Map<String, dynamic>;
    final summaryRaw = res['summary'] as Map<String, dynamic>? ?? {};
    final listRaw = res['data'] as List? ?? [];
    final meta = res['meta'] as Map<String, dynamic>? ?? {};

    return {
      'summary': CustomerBonusSummary.fromJson(summaryRaw),
      'bonuses': listRaw
          .map((item) => CustomerBonusModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      'total': (meta['total'] as num?)?.toInt() ?? listRaw.length,
    };
  }

  /// Get mutation logs for a customer bonus
  Future<List<CustomerBonusLogModel>> getLogs(int bonusId) async {
    if (DemoSessionManager.isDemoMode) {
      return [
        CustomerBonusLogModel(
          id: 1,
          customerBonusId: bonusId,
          customerPhone: '081234567890',
          orderCode: 'DEMO001',
          type: 'earn',
          transactionAmount: 50000,
          bonusPercent: 5,
          bonusAmount: 2500,
          balanceAfter: 2500,
          notes: 'Bonus 5% dari transaksi #DEMO001',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    }

    final res = await _client.get('/customer-bonuses/$bonusId/logs') as Map<String, dynamic>;
    final listRaw = res['data'] as List? ?? [];
    return listRaw
        .map((item) => CustomerBonusLogModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Claim / withdraw bonus
  Future<void> claimBonus(
    int bonusId, {
    required int amount,
    String? notes,
  }) async {
    if (DemoSessionManager.isDemoMode) {
      return;
    }

    await _client.post(
      '/customer-bonuses/$bonusId/claim',
      body: {
        'amount': amount,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }

  /// Register a specific customer to bonus program
  Future<CustomerBonusModel> createBonusCustomer({
    required String customerPhone,
    String? customerName,
    required int bonusPercent,
    String? notes,
  }) async {
    final res = await _client.post(
      '/customer-bonuses',
      body: {
        'customer_phone': customerPhone,
        if (customerName != null && customerName.trim().isNotEmpty)
          'customer_name': customerName.trim(),
        'bonus_percent': bonusPercent,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    ) as Map<String, dynamic>;

    final data = res['data'] as Map<String, dynamic>;
    return CustomerBonusModel.fromJson(data);
  }

  /// Update bonus customer info (percentage, active status, notes, name)
  Future<CustomerBonusModel> updateBonusCustomer(
    int bonusId, {
    String? customerName,
    required int bonusPercent,
    required bool isActive,
    String? notes,
  }) async {
    final res = await _client.put(
      '/customer-bonuses/$bonusId',
      body: {
        if (customerName != null) 'customer_name': customerName.trim(),
        'bonus_percent': bonusPercent,
        'is_active': isActive,
        'notes': notes?.trim() ?? '',
      },
    ) as Map<String, dynamic>;

    final data = res['data'] as Map<String, dynamic>;
    return CustomerBonusModel.fromJson(data);
  }

  /// Remove customer from bonus program
  Future<void> deleteBonusCustomer(int bonusId) async {
    await _client.delete('/customer-bonuses/$bonusId');
  }
}
