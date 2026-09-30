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
    // API client doesn't support put/patch directly in this simplistic version, but let's see. 
    // Assuming client has put or we used post. 
    // Wait, ApiClient only has get/post. 
    // Laravel allows Method Spoofing using _method=PUT.
    await _client.post('/categories/$id', body: {
      'name': name,
      '_method': 'PUT', 
    });
  }

  Future<void> deleteCategory(int id) async {
     await _client.post('/categories/$id', body: {
      '_method': 'DELETE',
    });
  }
}
