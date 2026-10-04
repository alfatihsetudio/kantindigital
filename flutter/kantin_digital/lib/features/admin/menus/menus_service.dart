import '../../../core/network/api_client.dart';
import '../../../core/utils/image_upload_helper.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/category_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class AdminMenusService {
  final ApiClient _client = ApiClient();

  Future<List<MenuModel>> getMenus() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getMenus();
    }
    final response = await _client.get('/menus');
    final data = response['data'] as List;
    return data.map((json) => MenuModel.fromJson(json)).toList();
  }

  Future<void> createMenu(
    Map<String, dynamic> body, {
    CompressedImageFile? image,
  }) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.createMenu(body);
      return;
    }

    if (image == null) {
      await _client.post('/menus', body: body);
      return;
    }

    await _client.postMultipart(
      '/menus',
      fields: _stringFields(body),
      fileField: 'image',
      fileBytes: image.bytes,
      filename: image.filename,
      contentType: image.mimeType,
    );
  }

  Future<void> updateMenu(
    int id,
    Map<String, dynamic> body, {
    CompressedImageFile? image,
  }) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.updateMenu(id, body);
      return;
    }

    final fields = _stringFields(body);
    if (image == null) {
      await _client.put('/menus/$id', body: fields);
      return;
    }

    await _client.postMultipart(
      '/menus/$id',
      fields: fields,
      fileField: 'image',
      fileBytes: image.bytes,
      filename: image.filename,
      contentType: image.mimeType,
    );
  }

  Future<void> deleteMenu(int id) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.deleteMenu(id);
      return;
    }
    await _client.delete('/menus/$id');
  }

  // Helper to fetch categories for dropdown
  Future<List<CategoryModel>> getCategories() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getCategories();
    }
    final response = await _client.get('/categories');
    final data = response['data'] as List;
    return data.map((json) => CategoryModel.fromJson(json)).toList();
  }

  Map<String, String> _stringFields(Map<String, dynamic> data) =>
      data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
}
