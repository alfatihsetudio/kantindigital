import '../../../shared/models/category_model.dart';
import 'categories_service.dart';

class AdminCategoriesController {
  final AdminCategoriesService _service = AdminCategoriesService();

  Future<List<CategoryModel>> fetchCategories() async {
    return _service.getCategories();
  }

  Future<void> addCategory(String name) async {
    await _service.createCategory(name);
  }

  Future<void> editCategory(int id, String name) async {
    await _service.updateCategory(id, name);
  }

  Future<void> deleteCategory(int id) async {
    await _service.deleteCategory(id);
  }
}
