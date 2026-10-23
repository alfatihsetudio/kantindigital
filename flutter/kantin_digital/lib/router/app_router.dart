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
import '../features/admin/profile/promo_settings_page.dart';
import '../features/admin/profile/logo_settings_page.dart';
import '../features/admin/profile/appearance_settings_page.dart';
import '../features/admin/profile/social_preview_settings_page.dart';
import '../features/admin/profile/order_sound_settings_page.dart';
import '../features/admin/vouchers/vouchers_page.dart';
import '../features/admin/stock_items/admin_stock_items_page.dart';
import '../features/admin/stock_report/admin_stock_report_page.dart';
import '../features/admin/cashier_reports/cashier_reports_page.dart';
import '../features/expenses/expenses_page.dart';
import '../features/admin/customer_bonus/customer_bonus_page.dart';
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

    // Normalisasi: buang trailing slash (contoh: /cashier/ -> /cashier)
    if (routeName != null && routeName.length > 1 && routeName.endsWith('/')) {
      routeName = routeName.substring(0, routeName.length - 1);
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
      case RouteName.admin:
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
      case RouteName.adminPromoSettings:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const PromoSettingsPage(),
          settings: settings,
        );
      case RouteName.adminLogoSettings:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const LogoSettingsPage(),
          settings: settings,
        );
      case RouteName.adminAppearanceSettings:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AppearanceSettingsPage(),
          settings: settings,
        );
      case RouteName.adminSocialPreviewSettings:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const SocialPreviewSettingsPage(),
          settings: settings,
        );
      case RouteName.adminOrderSound:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const OrderSoundSettingsPage(),
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
      case RouteName.adminCashierReports:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const AdminCashierReportsPage(),
          settings: settings,
        );
      case RouteName.adminExpenses:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const ExpensesPage(),
          settings: settings,
        );
      case RouteName.adminCustomerBonus:
        if (!session.isAuthenticated) {
          return MaterialPageRoute(
            builder: (_) => const AdminLoginPage(),
            settings: const RouteSettings(name: RouteName.adminLogin),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const CustomerBonusPage(),
          settings: settings,
        );

      // cashier
      case RouteName.cashier:
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
      case RouteName.cashierExpenses:
        return MaterialPageRoute(
          builder: (_) => const ExpensesPage(canInput: true),
          settings: settings,
        );

      // manager/pimpinan (read only)
      case RouteName.manager:
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
          builder: (context) => _NotFoundPage(routeName: settings.name),
          settings: settings,
        );
    }
  }
}

/// Tampilan 404 ketika URL/rute tidak ditemukan, dilengkapi tombol kembali & ke menu.
class _NotFoundPage extends StatelessWidget {
  final String? routeName;

  const _NotFoundPage({this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.alt_route_rounded,
                      color: Color(0xFF2563EB),
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Halaman Tidak Ditemukan',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Alamat "${routeName ?? ""}" tidak tersedia atau sudah dipindahkan.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteName.customerMenu,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 20),
                      label: const Text(
                        'Ke Halaman Menu Pembeli',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF16A34A),
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        backgroundColor: const Color(0xFFF0FDF4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteName.cashierOrders,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                      label: const Text(
                        'Ke Halaman Kasir',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          RouteName.adminDashboard,
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings_rounded, size: 18),
                      label: const Text('Dashboard Admin'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
