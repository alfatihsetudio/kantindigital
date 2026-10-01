import '../../../core/utils/image_upload_helper.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/category_model.dart';
import 'menus_service.dart';

class AdminMenusController {
  final AdminMenusService _service = AdminMenusService();

  Future<List<MenuModel>> fetchMenus() => _service.getMenus();
  Future<List<CategoryModel>> fetchCategories() => _service.getCategories();

  Future<void> addMenu(
    Map<String, dynamic> data, {
    CompressedImageFile? image,
  }) => _service.createMenu(data, image: image);
  Future<void> editMenu(
    int id,
    Map<String, dynamic> data, {
    CompressedImageFile? image,
  }) => _service.updateMenu(id, data, image: image);
  Future<void> deleteMenu(int id) => _service.deleteMenu(id);
}
