import 'package:flutter/material.dart';

import '../shared/models/menu_model.dart';
import '../features/customer/cart/cart_controller.dart';

import '../features/admin/auth/login_page.dart';
import '../features/admin/categories/categories_page.dart';
import '../features/admin/dashboard/dashboard_page.dart';

import '../features/admin/menus/menus_page.dart';
import '../features/admin/tables/tables_page.dart';
import '../features/admin/toppings/toppings_page.dart';
import '../features/admin/users/users_page.dart';
import '../features/cashier/order_detail/order_detail_page.dart';
import '../features/cashier/orders/orders_page.dart';
import '../features/customer/cart/cart_page.dart';
import '../features/customer/checkout/checkout_page.dart';
import '../features/customer/menu/menu_page.dart';
import '../features/customer/menu_detail/menu_detail_page.dart';
import '../features/customer/order_status/order_status_page.dart';
import '../features/manager/manager_dashboard_page.dart';
import '../features/manager/manager_menus_page.dart';
import '../features/manager/manager_categories_page.dart';
import '../features/manager/manager_users_page.dart';
import '../features/manager/manager_sales_page.dart';
import 'route_name.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Normalisasi: Jika URL mengandung query params di root (contoh: /?table=A1),
    // kita ambil data meja-nya, lalu arahkan ke menu.
    var routeName = settings.name;

    // Cek Query Param 'table'
    if (routeName != null && routeName.contains('table=')) {
      final uri = Uri.tryParse(routeName);
      if (uri != null) {
        final table = uri.queryParameters['table'];
        if (table != null && table.isNotEmpty) {
           CartController.instance.setTableNumber(table);
        }
      }
    }

    // Redirect /? to /
    if (routeName != null && routeName.startsWith('/?')) {
      routeName = RouteName.customerMenu;
    }

    switch (routeName) {
      // customer
      case RouteName.customerMenu:
        return MaterialPageRoute(builder: (_) => const MenuPage());
        
      case RouteName.customerMenuDetail:
        return MaterialPageRoute(
          builder: (context) {
            final args = settings.arguments as MenuModel;
            return MenuDetailPage(menu: args);
          },
        );
      case RouteName.customerCart:
        return MaterialPageRoute(builder: (_) => const CartPage());
      case RouteName.customerCheckout:
        return MaterialPageRoute(builder: (_) => const CheckoutPage());
      case RouteName.customerOrderStatus:
        return MaterialPageRoute(
          builder: (_) => const OrderStatusPage(),
          settings: settings,
        );

      // admin
      case RouteName.adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginPage());
      case RouteName.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());
      case RouteName.adminCategories:
        return MaterialPageRoute(builder: (_) => const AdminCategoriesPage());
      case RouteName.adminMenus:
        return MaterialPageRoute(builder: (_) => const AdminMenusPage());
      case RouteName.adminToppings:
        return MaterialPageRoute(builder: (_) => const AdminToppingsPage());

      case RouteName.adminTables:
        return MaterialPageRoute(builder: (_) => const AdminTablesPage());
      case RouteName.adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersPage());

      // cashier
      case RouteName.cashierOrders:
        return MaterialPageRoute(builder: (_) => const CashierOrdersPage());
      case RouteName.cashierOrderDetail:
        return MaterialPageRoute(builder: (_) => const CashierOrderDetailPage());

      // manager/pimpinan (read only)
      case RouteName.managerDashboard:
        return MaterialPageRoute(builder: (_) => const ManagerDashboardPage());
      case RouteName.managerMenus:
        return MaterialPageRoute(builder: (_) => const ManagerMenusPage());
      case RouteName.managerCategories:
        return MaterialPageRoute(builder: (_) => const ManagerCategoriesPage());
      case RouteName.managerUsers:
        return MaterialPageRoute(builder: (_) => const ManagerUsersPage());
      case RouteName.managerSales:
        return MaterialPageRoute(builder: (_) => const ManagerSalesPage());
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route tidak ditemukan: ${settings.name}')),
          ),
        );
    }
  }
}
