import '../../../core/network/api_client.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/category_model.dart';

class AdminMenusService {
  final ApiClient _client = ApiClient();

  Future<List<MenuModel>> getMenus() async {
    final response = await _client.get('/menus');
    final data = response['data'] as List;
    return data.map((json) => MenuModel.fromJson(json)).toList();
  }

  Future<void> createMenu(Map<String, dynamic> body) async {
    await _client.post('/menus', body: body);
  }

  Future<void> updateMenu(int id, Map<String, dynamic> body) async {
    body['_method'] = 'PUT';
    await _client.post('/menus/$id', body: body);
  }

  Future<void> deleteMenu(int id) async {
    await _client.post('/menus/$id', body: {'_method': 'DELETE'});
  }

  // Helper to fetch categories for dropdown
   Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get('/categories');
    final data = response['data'] as List;
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }
}
