import '../models/cart_item_model.dart';

class PromoDiscountCalculator {
  static int calculate({
    required Iterable<CartItemModel> items,
    required int percent,
    required bool appliesToAllMenus,
    required Set<int> menuIds,
  }) {
    final safePercent = percent.clamp(0, 100).toInt();
    if (safePercent == 0) return 0;

    return items.fold<int>(0, (total, item) {
      if (!appliesToAllMenus && !menuIds.contains(item.menu.id)) return total;
      final menuSubtotal = item.menu.price * item.quantity;
      return total + ((menuSubtotal * safePercent + 50) ~/ 100);
    });
  }
}
