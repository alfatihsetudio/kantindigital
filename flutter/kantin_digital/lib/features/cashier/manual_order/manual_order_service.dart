import '../../../core/network/api_client.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/models/topping_model.dart';
import '../../../shared/services/demo_session_manager.dart';

/// Service for Manual Order feature
class ManualOrderService {
  final ApiClient _client = ApiClient();

  /// Fetch all available menus
  Future<List<MenuModel>> getMenus() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getMenus().where((m) => m.isAvailable).toList();
    }
    final response = await _client.get('/menus');
    final rawList = (response is Map<String, dynamic> && response['data'] is List)
        ? response['data'] as List
        : (response is List ? response : []);
    return rawList
        .map((json) => MenuModel.fromJson(json as Map<String, dynamic>))
        .where((menu) => menu.isAvailable)
        .toList();
  }

  /// Fetch all tables
  Future<List<TableModel>> getTables() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getTables();
    }
    final response = await _client.get('/tables');
    final rawList = (response is Map<String, dynamic> && response['data'] is List)
        ? response['data'] as List
        : (response is List ? response : []);
    return rawList
        .map((json) => TableModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch toppings, optionall filtered by menu ID
  Future<List<ToppingModel>> getToppings({int? menuId}) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getToppings();
    }
    String endpoint = '/toppings';
    if (menuId != null) {
      endpoint = '/menus/$menuId/toppings';
    }

    final response = await _client.get(endpoint);
    final rawList = (response is Map<String, dynamic> && response['data'] is List)
        ? response['data'] as List
        : (response is List ? response : []);
    return rawList
        .map((json) => ToppingModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create a new order
  /// Returns order code on success
  Future<String> createOrder({
    String? tableCode,
    String? orderType,
    required List<ManualOrderItem> items,
    String? customerName,
    String? customerPhone,
    String? voucherCode,
  }) async {
    final rawItems = items.map((e) {
      List<int> toppingIds = [];
      for (var t in e.toppings) {
        for (int i = 0; i < t.quantity; i++) {
          toppingIds.add(t.id);
        }
      }
      return {
        'menu_id': e.menuId,
        'quantity': e.quantity,
        'topping_ids': toppingIds,
        'notes': e.notes ?? '',
      };
    }).toList();

    final hasTable = tableCode != null && tableCode.trim().isNotEmpty;
    final effectiveOrderType = orderType ?? (hasTable ? 'dine_in' : 'pickup');

    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.createManualOrder(
        tableCode: hasTable ? tableCode.trim() : null,
        orderType: effectiveOrderType,
        customerName: customerName ?? '',
        customerPhone: customerPhone ?? '',
        items: rawItems,
        voucherCode: voucherCode,
      );
    }

    final body = {
      if (hasTable) 'table_code': tableCode.trim(),
      'order_type': effectiveOrderType,
      'customer_name': customerName ?? '',
      'customer_phone': customerPhone ?? '',
      if (voucherCode != null && voucherCode.trim().isNotEmpty)
        'voucher_code': voucherCode.trim(),
      'items': rawItems,
    };

    final json =
        await _client.post('/orders', body: body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return (data['code'] ?? '').toString();
  }
}

/// Model for manual order item
class ManualOrderItem {
  final int menuId;
  final MenuModel? menu; // Optional reference for UI convenience
  final int quantity;
  final List<ToppingModel> toppings;
  final String? notes;

  ManualOrderItem({
    required this.menuId,
    this.menu,
    required this.quantity,
    this.toppings = const [],
    this.notes,
  });

  int get totalPerItem {
    int mPrice = menu?.price ?? 0;
    int tPrice = toppings.fold(0, (sum, t) => sum + (t.price * t.quantity));
    return mPrice + tPrice;
  }
}
