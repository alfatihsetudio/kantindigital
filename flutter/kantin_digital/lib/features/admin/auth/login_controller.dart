import '../../../router/route_name.dart';
import '../../../shared/auth/auth_session.dart';

import '../../../shared/constants/user_role.dart';
import 'login_service.dart';

class AdminLoginController {
  final AdminAuthService _service;
  final AuthSession _session = AuthSession();

  AdminLoginController({AdminAuthService? service})
    : _service = service ?? AdminAuthService();

  Future<String?> login({
    required String email,
    required String password,
    required void Function(String routeName) onNavigate,
  }) async {
    try {
      final result = await _service.login(email: email, password: password);
      _session.setSession(token: result.token, user: result.user);

      // Redirect berdasar role
      final role = result.user.role;
      switch (role) {
        case null:
          return 'Role user tidak ditemukan';
        case UserRole.admin:
          onNavigate(RouteName.adminDashboard);
          break;
        case UserRole.cashier:
          onNavigate(RouteName.cashierOrders);
          break;
        case UserRole.operations:
          onNavigate(RouteName.cashierOrders);
          break;
        case UserRole.manager:
          onNavigate(RouteName.managerDashboard);
          break;
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
