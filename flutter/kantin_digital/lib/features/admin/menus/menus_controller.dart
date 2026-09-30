import '../../../shared/models/menu_model.dart';
import '../../../shared/models/category_model.dart';
import 'menus_service.dart';

class AdminMenusController {
  final AdminMenusService _service = AdminMenusService();

  Future<List<MenuModel>> fetchMenus() => _service.getMenus();
  Future<List<CategoryModel>> fetchCategories() => _service.getCategories();
  
  Future<void> addMenu(Map<String, dynamic> data) => _service.createMenu(data);
  Future<void> editMenu(int id, Map<String, dynamic> data) => _service.updateMenu(id, data);
  Future<void> deleteMenu(int id) => _service.deleteMenu(id);
}
