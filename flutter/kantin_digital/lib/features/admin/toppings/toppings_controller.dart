import '../../../shared/models/topping_model.dart';
import 'toppings_service.dart';

class AdminToppingsController {
  final AdminToppingsService _service = AdminToppingsService();

  Future<List<ToppingModel>> fetchToppings() => _service.getToppings();
  Future<void> addTopping(String name, int price, int menuId) => _service.createTopping({'name': name, 'price': price, 'menu_id': menuId});
  Future<void> editTopping(int id, String name, int price, int menuId) => _service.updateTopping(id, {'name': name, 'price': price, 'menu_id': menuId});
  Future<void> deleteTopping(int id) => _service.deleteTopping(id);
}
