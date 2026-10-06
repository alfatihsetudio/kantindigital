import '../../../core/network/api_client.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/topping_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class MenuService {
  final ApiClient _client;

  MenuService(this._client);

  Future<List<MenuModel>> fetchMenus({bool includeUnavailable = false}) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.demoMenus;
    }

    final json = await _client.get('/menus');

    if (json is Map<String, dynamic>) {
      final raw = json['data'];
      if (raw is List) {
        return raw
            .map((e) => MenuModel.fromJson(e as Map<String, dynamic>))
            .where((menu) => includeUnavailable || menu.isAvailable)
            .toList();
      }
    }

    // fallback (kalau backend return list langsung)
    if (json is List) {
      return json
          .map((e) => MenuModel.fromJson(e as Map<String, dynamic>))
          .where((menu) => includeUnavailable || menu.isAvailable)
          .toList();
    }

    return const [];
  }

  Future<List<ToppingModel>> fetchToppings(int menuId) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.demoToppings;
    }

    final json = await _client.get('/menus/$menuId/toppings');

    if (json is Map<String, dynamic>) {
      final raw = json['data'];
      if (raw is List) {
        return raw
            .map((e) => ToppingModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    // fallback (kalau backend return list langsung)
    if (json is List) {
      return json
          .map((e) => ToppingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return const [];
  }
}
