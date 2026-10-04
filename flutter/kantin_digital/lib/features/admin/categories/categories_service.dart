import '../../../core/network/api_client.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class AdminCategoriesService {
  final ApiClient _client = ApiClient();

  Future<List<CategoryModel>> getCategories() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getCategories();
    }
    final response = await _client.get('/categories');
    final data = response['data'] as List;
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<void> createCategory(String name) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.createCategory(name);
      return;
    }
    await _client.post('/categories', body: {'name': name});
  }

  Future<void> updateCategory(int id, String name) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.updateCategory(id, name);
      return;
    }
    await _client.put('/categories/$id', body: {'name': name});
  }

  Future<CategoryModel> toggleCategory(int id) async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.toggleCategory(id);
    }
    final response = await _client.post('/categories/$id/toggle', body: {});
    return CategoryModel.fromJson(response['data']);
  }

  Future<void> deleteCategory(int id) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.deleteCategory(id);
      return;
    }
    await _client.delete('/categories/$id');
  }
}
