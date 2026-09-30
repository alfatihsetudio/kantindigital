import '../../../core/network/api_client.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/topping_model.dart';

class MenuService {
  final ApiClient _client;

  MenuService(this._client);

  Future<List<MenuModel>> fetchMenus() async {
    final json = await _client.get('/menus');

    if (json is Map<String, dynamic>) {
      final raw = json['data'];
      if (raw is List) {
        return raw.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    // fallback (kalau backend return list langsung)
    if (json is List) {
      return json.map((e) => MenuModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return const [];
  }

  Future<List<ToppingModel>> fetchToppings() async {
    final json = await _client.get('/toppings');

    if (json is Map<String, dynamic>) {
      final raw = json['data'];
      if (raw is List) {
        return raw.map((e) => ToppingModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    }

    // fallback (kalau backend return list langsung)
    if (json is List) {
      return json.map((e) => ToppingModel.fromJson(e as Map<String, dynamic>)).toList();
    }

    return const [];
  }
}

