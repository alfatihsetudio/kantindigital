import '../../../shared/models/topping_model.dart';
import 'toppings_service.dart';

class AdminToppingsController {
  final AdminToppingsService _service = AdminToppingsService();

  Future<List<ToppingModel>> fetchToppings() => _service.getToppings();
  Future<void> addTopping(String name, int price, List<int> categoryIds) =>
      _service.createTopping({
        'name': name,
        'price': price,
        'category_ids': categoryIds,
      });
  Future<void> editTopping(
    int id,
    String name,
    int price,
    List<int> categoryIds,
  ) =>
      _service.updateTopping(id, {
        'name': name,
        'price': price,
        'category_ids': categoryIds,
      });
  Future<void> deleteTopping(int id) => _service.deleteTopping(id);
}
