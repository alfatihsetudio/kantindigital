import '../../../core/network/api_client.dart';
import 'menu_service.dart';
import '../../../shared/models/menu_model.dart';

class MenuController {
  final MenuService _service;

  MenuController({ApiClient? client}) : _service = MenuService(client ?? ApiClient());

  Future<List<MenuModel>> fetchMenus() => _service.fetchMenus();
}

