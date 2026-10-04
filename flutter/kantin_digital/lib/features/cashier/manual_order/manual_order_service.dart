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
    final data = response['data'] as List;
    return data
        .map((json) => MenuModel.fromJson(json))
        .where((menu) => menu.isAvailable)
        .toList();
  }

  /// Fetch all tables
  Future<List<TableModel>> getTables() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getTables();
    }
    final response = await _client.get('/tables');
    final data = response['data'] as List;
    return data.map((json) => TableModel.fromJson(json)).toList();
  }

  /// Fetch toppings, optionall filtered by menu ID
  Future<List<ToppingModel>> getToppings({int? menuId}) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getToppings();
    }
    String endpoint = '/toppings';
    if (menuId != null) {
      endpoint += '?menu_id=$menuId';
    }

    final response = await _client.get(endpoint);
    final data = response['data'] as List;
    return data.map((json) => ToppingModel.fromJson(json)).toList();
  }

  /// Create a new order
  /// Returns order code on success
  Future<String> createOrder({
    required String tableCode,
    required List<ManualOrderItem> items,
    String? customerName,
    String? customerPhone,
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

    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.createManualOrder(
        tableCode: tableCode,
        customerName: customerName ?? '',
        customerPhone: customerPhone ?? '',
        items: rawItems,
      );
    }

    final body = {
      'table_code': tableCode,
      'customer_name': customerName ?? '',
      'customer_phone': customerPhone ?? '',
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
