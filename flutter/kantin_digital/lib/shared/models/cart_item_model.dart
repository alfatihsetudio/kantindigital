import 'menu_model.dart';
import 'topping_model.dart';

class CartItemModel {
  final MenuModel menu;
  final int quantity;
  final List<ToppingModel> toppings;
  final String? notes;

  CartItemModel({
    required this.menu,
    required this.quantity,
    List<ToppingModel>? toppings,
    this.notes,
  }) : toppings = toppings ?? [];

  int get toppingsTotal => toppings.fold(0, (sum, t) => sum + (t.price * t.quantity));
  
  int get subtotal => (menu.price * quantity) + toppingsTotal;
}
