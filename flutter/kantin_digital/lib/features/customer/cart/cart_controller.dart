import 'package:flutter/foundation.dart';

import '../../../shared/models/cart_item_model.dart';
import '../../../shared/models/menu_model.dart';
import '../../../shared/models/topping_model.dart';

/// Cart Controller with ChangeNotifier for reactive UI updates
class CartController extends ChangeNotifier {
  CartController._();

  static final CartController instance = CartController._();

  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  /// Total price of all items in cart
  int get totalAmount => _items.fold(0, (sum, item) => sum + item.subtotal);
  
  /// Total number of items in cart
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;
  
  /// Check if cart is not empty
  bool get isNotEmpty => _items.isNotEmpty;

  String? _tableNumber;
  String? get tableNumber => _tableNumber;

  /// Set locked table number from QR Scan
  void setTableNumber(String? number) {
    if (_tableNumber != number) {
      _tableNumber = number;
      notifyListeners();
    }
  }

  void addMenu(MenuModel menu, {int quantity = 1, String? notes, List<Map<String, dynamic>>? toppings}) {
    final toppingModels = toppings?.map((t) => ToppingModel(
      id: t['id'] as int,
      name: t['name'] as String,
      price: t['price'] as int,
      quantity: (t['quantity'] as int?) ?? 1,
    )).toList() ?? [];

    // If item with same menu and same toppings exists, increase quantity
    final existingIndex = _items.indexWhere((e) => 
      e.menu.id == menu.id && _sameToppings(e.toppings, toppingModels));
    
    if (existingIndex >= 0) {
      final existing = _items[existingIndex];
      _items[existingIndex] = CartItemModel(
        menu: existing.menu,
        quantity: existing.quantity + quantity,
        toppings: existing.toppings,
        notes: notes ?? existing.notes,
      );
    } else {
      _items.add(CartItemModel(
        menu: menu, 
        quantity: quantity, 
        toppings: toppingModels,
        notes: notes,
      ));
    }
    notifyListeners();
  }

  bool _sameToppings(List<ToppingModel> a, List<ToppingModel> b) {
    if (a.length != b.length) return false;
    final aIds = a.map((t) => t.id).toSet();
    final bIds = b.map((t) => t.id).toSet();
    return aIds.length == bIds.length && aIds.containsAll(bIds);
  }

  /// Remove item by menu ID
  void removeItem(int menuId) {
    _items.removeWhere((item) => item.menu.id == menuId);
    notifyListeners();
  }
  
  /// Remove item at specific index
  void removeAt(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }
  
  /// Update quantity for item at index
  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length && quantity > 0) {
      final existing = _items[index];
      _items[index] = CartItemModel(
        menu: existing.menu,
        quantity: quantity,
        toppings: existing.toppings,
        notes: existing.notes,
      );
      notifyListeners();
    }
  }
  
  /// Increment quantity for item at index
  void incrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      updateQuantity(index, _items[index].quantity + 1);
    }
  }
  
  /// Decrement quantity for item at index
  void decrementQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      final current = _items[index].quantity;
      if (current > 1) {
        updateQuantity(index, current - 1);
      } else {
        removeAt(index);
      }
    }
  }

  /// Update toppings for item at index
  void updateToppings(int index, List<ToppingModel> toppings) {
    if (index >= 0 && index < _items.length) {
      final existing = _items[index];
      _items[index] = CartItemModel(
        menu: existing.menu,
        quantity: existing.quantity,
        toppings: toppings,
        notes: existing.notes,
      );
      notifyListeners();
    }
  }

  /// Update quantity of a specific topping in a cart item
  void updateToppingQuantity(int itemIndex, int toppingId, int quantity) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      final existing = _items[itemIndex];
      final updatedToppings = existing.toppings.map((t) {
        if (t.id == toppingId) {
          return ToppingModel(id: t.id, name: t.name, price: t.price, quantity: quantity);
        }
        return t;
      }).where((t) => t.quantity > 0).toList();
      
      _items[itemIndex] = CartItemModel(
        menu: existing.menu,
        quantity: existing.quantity,
        toppings: updatedToppings,
        notes: existing.notes,
      );
      notifyListeners();
    }
  }

  /// Remove a specific topping from a cart item
  void removeTopping(int itemIndex, int toppingId) {
    if (itemIndex >= 0 && itemIndex < _items.length) {
      final existing = _items[itemIndex];
      final updatedToppings = existing.toppings.where((t) => t.id != toppingId).toList();
      
      _items[itemIndex] = CartItemModel(
        menu: existing.menu,
        quantity: existing.quantity,
        toppings: updatedToppings,
        notes: existing.notes,
      );
      notifyListeners();
    }
  }

  /// Update notes for item at index
  void updateNotes(int index, String notes) {
    if (index >= 0 && index < _items.length) {
      final existing = _items[index];
      _items[index] = CartItemModel(
        menu: existing.menu,
        quantity: existing.quantity,
        toppings: existing.toppings,
        notes: notes,
      );
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
