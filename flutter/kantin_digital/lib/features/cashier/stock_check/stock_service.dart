import '../../../core/network/api_client.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/models/stock_item_model.dart';
import '../../../shared/models/stock_check_model.dart';

class StockService {
  final ApiClient _client;

  StockService({ApiClient? client}) : _client = client ?? ApiClient();

  /// Mendapatkan daftar master item stok (bahan baku, kemasan, dll)
  Future<List<StockItemModel>> getStockItems({bool activeOnly = true}) async {
    try {
      final res = await _client.get(
        'stock-items',
        queryParameters: {'active_only': activeOnly ? '1' : '0'},
      );

      if (res is Map<String, dynamic> && res['status'] == true && res['data'] is List) {
        return (res['data'] as List)
            .map((item) => StockItemModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e, stack) {
      AppLogger.error('StockService.getStockItems failed: $e\n$stack');
      rethrow;
    }
  }

  /// Tambah item stok master baru
  Future<StockItemModel> createStockItem({
    required String name,
    required String unit,
    String? category,
  }) async {
    try {
      final res = await _client.post(
        'stock-items',
        body: {
          'name': name.trim(),
          'unit': unit.trim(),
          'category': category?.trim() ?? 'Bahan Baku',
        },
      );

      if (res is Map<String, dynamic> && res['status'] == true && res['data'] is Map<String, dynamic>) {
        return StockItemModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception(res['message'] ?? 'Gagal menambahkan item');
    } catch (e, stack) {
      AppLogger.error('StockService.createStockItem failed: $e\n$stack');
      rethrow;
    }
  }

  /// Perbarui item stok
  Future<StockItemModel> updateStockItem(
    int id, {
    String? name,
    String? unit,
    String? category,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name.trim();
      if (unit != null) data['unit'] = unit.trim();
      if (category != null) data['category'] = category.trim();
      if (isActive != null) data['is_active'] = isActive;

      final res = await _client.put(
        'stock-items/$id',
        body: data,
      );
      if (res is Map<String, dynamic> && res['status'] == true && res['data'] is Map<String, dynamic>) {
        return StockItemModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception(res['message'] ?? 'Gagal memperbarui item');
    } catch (e, stack) {
      AppLogger.error('StockService.updateStockItem failed: $e\n$stack');
      rethrow;
    }
  }

  /// Hapus item stok
  Future<void> deleteStockItem(int id) async {
    try {
      final res = await _client.delete('stock-items/$id');
      if (res is Map<String, dynamic> && res['status'] == true) {
        return;
      }
      throw Exception(res['message'] ?? 'Gagal menghapus item');
    } catch (e, stack) {
      AppLogger.error('StockService.deleteStockItem failed: $e\n$stack');
      rethrow;
    }
  }

  /// Mengambil catatan closing terakhir untuk acuan Buka Toko (Opening)
  Future<StockCheckModel?> getLatestClosing() async {
    try {
      final res = await _client.get('stock-checks/latest-closing');
      if (res is Map<String, dynamic> && res['status'] == true && res['data'] != null) {
        return StockCheckModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e, stack) {
      AppLogger.error('StockService.getLatestClosing failed: $e\n$stack');
      return null;
    }
  }

  /// Riwayat catatan stok (Buka & Tutup toko)
  Future<List<StockCheckModel>> getStockChecks({String? type, String? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (type != null && type.isNotEmpty) queryParams['type'] = type;
      if (date != null && date.isNotEmpty) queryParams['date'] = date;

      final res = await _client.get('stock-checks', queryParameters: queryParams);
      if (res is Map<String, dynamic> && res['status'] == true && res['data'] is List) {
        return (res['data'] as List)
            .map((item) => StockCheckModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e, stack) {
      AppLogger.error('StockService.getStockChecks failed: $e\n$stack');
      rethrow;
    }
  }

  /// Detail catatan stok berdasarkan ID
  Future<StockCheckModel> getStockCheckDetail(int id) async {
    try {
      final res = await _client.get('stock-checks/$id');
      if (res is Map<String, dynamic> && res['status'] == true && res['data'] is Map<String, dynamic>) {
        return StockCheckModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception(res['message'] ?? 'Gagal memuat detail catatan stok');
    } catch (e, stack) {
      AppLogger.error('StockService.getStockCheckDetail failed: $e\n$stack');
      rethrow;
    }
  }

  /// Simpan catatan stok (Opening atau Closing)
  Future<StockCheckModel> saveStockCheck({
    required String checkType,
    String? checkDate,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final payload = {
        'check_type': checkType,
        if (checkDate != null) 'check_date': checkDate,
        if (notes != null) 'notes': notes,
        'items': items,
      };

      final res = await _client.post(
        'stock-checks',
        body: payload,
      );
      if (res is Map<String, dynamic> && res['status'] == true && res['data'] is Map<String, dynamic>) {
        return StockCheckModel.fromJson(res['data'] as Map<String, dynamic>);
      }
      throw Exception(res['message'] ?? 'Gagal menyimpan catatan stok');
    } catch (e, stack) {
      AppLogger.error('StockService.saveStockCheck failed: $e\n$stack');
      rethrow;
    }
  }
}
