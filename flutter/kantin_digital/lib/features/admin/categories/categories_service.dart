import '../../../core/network/api_client.dart';
import '../../../shared/models/category_model.dart';

class AdminCategoriesService {
  final ApiClient _client = ApiClient();

  Future<List<CategoryModel>> getCategories() async {
    final response = await _client.get('/categories');
    final data = response['data'] as List;
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Future<void> createCategory(String name) async {
    await _client.post('/categories', body: {'name': name});
  }

  Future<void> updateCategory(int id, String name) async {
    await _client.put('/categories/$id', body: {'name': name});
  }

  Future<CategoryModel> toggleCategory(int id) async {
    final response = await _client.post('/categories/$id/toggle', body: {});
    return CategoryModel.fromJson(response['data']);
  }

  Future<void> deleteCategory(int id) async {
    await _client.delete('/categories/$id');
  }
}
