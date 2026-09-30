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
import '../shared/auth/auth_session.dart';
import '../shared/constants/user_role.dart';
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
        return MaterialPageRoute(builder: (_) => const MenuPage(), settings: settings);
        
      case RouteName.customerMenuDetail:
        return MaterialPageRoute(
          builder: (context) {
            final args = settings.arguments as MenuModel;
            return MenuDetailPage(menu: args);
          },
          settings: settings,
        );
      case RouteName.customerCart:
        return MaterialPageRoute(builder: (_) => const CartPage(), settings: settings);
      case RouteName.customerCheckout:
        return MaterialPageRoute(builder: (_) => const CheckoutPage(), settings: settings);
      case RouteName.customerOrderStatus:
        return MaterialPageRoute(
          builder: (_) => const OrderStatusPage(),
          settings: settings,
        );

      // admin
      case RouteName.adminLogin:
        final session = AuthSession();
        if (session.isAuthenticated && session.role != null) {
          switch (session.role!) {
            case UserRole.admin:
              return MaterialPageRoute(builder: (_) => const AdminDashboardPage(), settings: const RouteSettings(name: RouteName.adminDashboard));
            case UserRole.cashier:
              return MaterialPageRoute(builder: (_) => const CashierOrdersPage(), settings: const RouteSettings(name: RouteName.cashierOrders));
            case UserRole.manager:
              return MaterialPageRoute(builder: (_) => const ManagerDashboardPage(), settings: const RouteSettings(name: RouteName.managerDashboard));
          }
        }
        return MaterialPageRoute(builder: (_) => const AdminLoginPage(), settings: settings);
      case RouteName.adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage(), settings: settings);
      case RouteName.adminCategories:
        return MaterialPageRoute(builder: (_) => const AdminCategoriesPage(), settings: settings);
      case RouteName.adminMenus:
        return MaterialPageRoute(builder: (_) => const AdminMenusPage(), settings: settings);
      case RouteName.adminToppings:
        return MaterialPageRoute(builder: (_) => const AdminToppingsPage(), settings: settings);

      case RouteName.adminTables:
        return MaterialPageRoute(builder: (_) => const AdminTablesPage(), settings: settings);
      case RouteName.adminUsers:
        return MaterialPageRoute(builder: (_) => const AdminUsersPage(), settings: settings);

      // cashier
      case RouteName.cashierOrders:
        return MaterialPageRoute(builder: (_) => const CashierOrdersPage(), settings: settings);
      case RouteName.cashierOrderDetail:
        return MaterialPageRoute(builder: (_) => const CashierOrderDetailPage(), settings: settings);

      // manager/pimpinan (read only)
      case RouteName.managerDashboard:
        return MaterialPageRoute(builder: (_) => const ManagerDashboardPage(), settings: settings);
      case RouteName.managerMenus:
        final categoryArg = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ManagerMenusPage(initialCategory: categoryArg),
          settings: settings,
        );
      case RouteName.managerCategories:
        return MaterialPageRoute(builder: (_) => const ManagerCategoriesPage(), settings: settings);
      case RouteName.managerUsers:
        return MaterialPageRoute(builder: (_) => const ManagerUsersPage(), settings: settings);
      case RouteName.managerSales:
        return MaterialPageRoute(builder: (_) => const ManagerSalesPage(), settings: settings);
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route tidak ditemukan: ${settings.name}')),
          ),
        );
    }
  }
}
