import '../../shared/models/expense_model.dart';
import '../../shared/services/demo_session_manager.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/logger.dart';

/// Layanan daftar belanja / pengeluaran operasional.
/// Input dilakukan oleh kasir, sedangkan admin/owner & manajer hanya melihat.
class ExpenseService {
  final ApiClient _client;

  ExpenseService({ApiClient? client}) : _client = client ?? ApiClient();

  ExpenseListResult _parse(Map<String, dynamic> res) {
    final rawList = res['data'];
    final expenses = (rawList is List)
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map((e) => ExpenseModel.fromJson(e))
            .toList()
        : <ExpenseModel>[];

    final summary = res['summary'];
    final summaryMap = summary is Map<String, dynamic> ? summary : const <String, dynamic>{};

    return ExpenseListResult(
      expenses: expenses,
      totalAmount: (summaryMap['total_amount'] as num?)?.toDouble() ??
          expenses.fold<double>(0, (sum, e) => sum + e.amount),
      totalTransactions:
          (summaryMap['total_transactions'] as num?)?.toInt() ?? expenses.length,
    );
  }

  /// Ambil daftar pengeluaran (opsional filter rentang tanggal & kategori).
  Future<ExpenseListResult> fetchExpenses({
    String? startDate,
    String? endDate,
    String? category,
    int limit = 100,
  }) async {
    try {
      final Map<String, dynamic> res;
      if (DemoSessionManager.isDemoMode) {
        res = DemoSessionManager.getExpenses(
          startDate: startDate,
          endDate: endDate,
          category: category,
        );
      } else {
        final queryParams = <String, dynamic>{'limit': limit};
        if (startDate != null && startDate.isNotEmpty) {
          queryParams['start_date'] = startDate;
        }
        if (endDate != null && endDate.isNotEmpty) {
          queryParams['end_date'] = endDate;
        }
        if (category != null && category.isNotEmpty) {
          queryParams['category'] = category;
        }
        res = await _client.get('expenses', queryParameters: queryParams)
            as Map<String, dynamic>;
      }
      return _parse(res);
    } catch (e, stack) {
      AppLogger.error('ExpenseService.fetchExpenses failed: $e\n$stack');
      rethrow;
    }
  }

  /// Catat pengeluaran baru (input kasir).
  Future<ExpenseModel> createExpense({
    required String expenseDate,
    required String category,
    required String description,
    required double amount,
    int? stockItemId,
    double? quantity,
    String? unit,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'expense_date': expenseDate,
        'category': category,
        'description': description.trim(),
        'amount': amount,
        if (stockItemId != null) 'stock_item_id': stockItemId,
        if (quantity != null) 'quantity': quantity,
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      };

      final Map<String, dynamic> res;
      if (DemoSessionManager.isDemoMode) {
        res = DemoSessionManager.createExpense(payload);
      } else {
        res = await _client.post('expenses', body: payload) as Map<String, dynamic>;
      }

      if (res['status'] == true && res['data'] is Map<String, dynamic>) {
        return ExpenseModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception(res['message'] ?? 'Gagal menyimpan pengeluaran');
    } catch (e, stack) {
      AppLogger.error('ExpenseService.createExpense failed: $e\n$stack');
      rethrow;
    }
  }

  /// Perbarui catatan pengeluaran.
  Future<ExpenseModel> updateExpense(
    int id, {
    required String expenseDate,
    required String category,
    required String description,
    required double amount,
    int? stockItemId,
    double? quantity,
    String? unit,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'expense_date': expenseDate,
        'category': category,
        'description': description.trim(),
        'amount': amount,
        if (stockItemId != null) 'stock_item_id': stockItemId,
        if (quantity != null) 'quantity': quantity,
        if (unit != null) 'unit': unit.trim(),
        'notes': notes?.trim(),
      };

      final Map<String, dynamic> res;
      if (DemoSessionManager.isDemoMode) {
        res = DemoSessionManager.updateExpense(id, payload);
      } else {
        res = await _client.put('expenses/$id', body: payload) as Map<String, dynamic>;
      }

      if (res['status'] == true && res['data'] is Map<String, dynamic>) {
        return ExpenseModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception(res['message'] ?? 'Gagal memperbarui pengeluaran');
    } catch (e, stack) {
      AppLogger.error('ExpenseService.updateExpense failed: $e\n$stack');
      rethrow;
    }
  }

  /// Hapus catatan pengeluaran.
  Future<void> deleteExpense(int id) async {
    try {
      final Map<String, dynamic> res;
      if (DemoSessionManager.isDemoMode) {
        res = DemoSessionManager.deleteExpense(id);
      } else {
        res = await _client.delete('expenses/$id') as Map<String, dynamic>;
      }

      if (res['status'] == true) return;
      throw Exception(res['message'] ?? 'Gagal menghapus pengeluaran');
    } catch (e, stack) {
      AppLogger.error('ExpenseService.deleteExpense failed: $e\n$stack');
      rethrow;
    }
  }
}
