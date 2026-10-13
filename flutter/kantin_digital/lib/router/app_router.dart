import 'package:flutter/material.dart';

import '../shared/models/menu_model.dart';
import '../features/customer/cart/cart_controller.dart';
import '../features/landing/landing_page.dart';
import '../features/landing/buy_website_page.dart';
import '../features/landing/store_showcase_page.dart';
import '../features/demo/demo_hub_page.dart';
import '../shared/services/demo_session_manager.dart';
import '../shared/services/tenant_service.dart';

import '../features/admin/auth/login_page.dart';
import '../features/admin/auth/force_password_change_page.dart';
import '../features/admin/categories/categories_page.dart';
import '../features/admin/dashboard/dashboard_page.dart';

import '../features/admin/menus/menus_page.dart';
import '../features/admin/tables/tables_page.dart';
import '../features/admin/toppings/toppings_page.dart';
import '../features/admin/users/users_page.dart';
import '../features/admin/qris/qris_setting_page.dart';
import '../features/admin/profile/tenant_profile_page.dart';
import '../features/admin/vouchers/vouchers_page.dart';
import '../features/admin/stock_items/admin_stock_items_page.dart';
import '../features/admin/stock_report/admin_stock_report_page.dart';
import '../features/superadmin/superadmin_dashboard_page.dart';
import '../features/cashier/order_detail/order_detail_page.dart';
import '../features/cashier/orders/orders_page.dart';
import '../features/cashier/stock_check/stock_check_page.dart';
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

    final session = AuthSession();
    if (session.isAuthenticated &&
        session.user?.mustChangePassword == true &&
        routeName != RouteName.forcePasswordChange) {
      routeName = RouteName.forcePasswordChange;
    }

    switch (routeName) {
      // platform landing page
      case RouteName.landingPage:
        return MaterialPageRoute(
          builder: (_) => const LandingPage(),
          settings: settings,
        );

      case RouteName.demoMenu:
        DemoSessionManager.enableDemoMode();
        return MaterialPageRoute(
          builder: (_) => const DemoHubPage(),
          settings: settings,
        );

      case RouteName.buyWebsite:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BuyWebsitePage(
            initialSubdomain: args?['subdomain']?.toString(),
            initialPlan: args?['plan']?.toString(),
          ),
          settings: settings,
        );

      case RouteName.storeShowcase:
        return MaterialPageRoute(
          builder: (_) => const StoreShowcasePage(),
          settings: settings,
        );

      // customer
      case RouteName.customerMenu:
        if (TenantService.isRootDomain && !DemoSessionManager.isDemoMode) {
          return MaterialPageRoute(
            builder: (_) => const LandingPage(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const MenuPage(),
          settings: settings,
        );

      case RouteName.customerMenuDetail:
        return MaterialPageRoute(
          builder: (context) {
            final args = settings.arguments as MenuModel;
            return MenuDetailPage(menu: args);
          },
          settings: settings,
        );
      case RouteName.customerCart:
        return MaterialPageRoute(
          builder: (_) => const CartPage(),
          settings: settings,
        );
      case RouteName.customerCheckout:
        return MaterialPageRoute(
          builder: (_) => const CheckoutPage(),
          settings: settings,
        );
      case RouteName.customerOrderStatus:
        return MaterialPageRoute(
          builder: (_) => const OrderStatusPage(),
          settings: settings,
        );

      // admin
      case RouteName.adminLogin:
        return MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
          settings: settings,
        );
      case RouteName.forcePasswordChange:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const ForcePasswordChangePage(),
          settings: settings,
        );
      case RouteName.superAdminDashboard:
        if (AuthSession().isAuthenticated &&
            AuthSession().role == UserRole.superadmin) {
          return MaterialPageRoute(
            builder: (_) => const SuperAdminDashboardPage(),
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminLoginPage(),
          settings: const RouteSettings(name: RouteName.adminLogin),
        );
      case RouteName.adminDashboard:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardPage(),
          settings: settings,
        );
      case RouteName.adminCategories:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminCategoriesPage(),
          settings: settings,
        );
      case RouteName.adminMenus:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminMenusPage(),
          settings: settings,
        );
      case RouteName.adminToppings:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminToppingsPage(),
          settings: settings,
        );

      case RouteName.adminTables:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminTablesPage(),
          settings: settings,
        );
      case RouteName.adminUsers:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminUsersPage(),
          settings: settings,
        );
      case RouteName.adminQris:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const QrisSettingPage(),
          settings: settings,
        );
      case RouteName.adminTenantProfile:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminTenantProfilePage(),
          settings: settings,
        );
      case RouteName.adminVouchers:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminVouchersPage(),
          settings: settings,
        );
      case RouteName.adminStockItems:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminStockItemsPage(),
          settings: settings,
        );
      case RouteName.adminStockReport:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminStockReportPage(),
          settings: settings,
        );

      // cashier
      case RouteName.cashierOrders:
        return MaterialPageRoute(
          builder: (_) => const CashierOrdersPage(),
          settings: settings,
        );
      case RouteName.cashierOrderDetail:
        return MaterialPageRoute(
          builder: (_) => const CashierOrderDetailPage(),
          settings: settings,
        );
      case RouteName.cashierStockCheck:
        return MaterialPageRoute(
          builder: (_) => const CashierStockCheckPage(),
          settings: settings,
        );

      // manager/pimpinan (read only)
      case RouteName.managerDashboard:
        return MaterialPageRoute(
          builder: (_) => const ManagerDashboardPage(),
          settings: settings,
        );
      case RouteName.managerMenus:
        final categoryArg = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => ManagerMenusPage(initialCategory: categoryArg),
          settings: settings,
        );
      case RouteName.managerCategories:
        return MaterialPageRoute(
          builder: (_) => const ManagerCategoriesPage(),
          settings: settings,
        );
      case RouteName.managerUsers:
        return MaterialPageRoute(
          builder: (_) => const ManagerUsersPage(),
          settings: settings,
        );
      case RouteName.managerSales:
        return MaterialPageRoute(
          builder: (_) => const ManagerSalesPage(),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
