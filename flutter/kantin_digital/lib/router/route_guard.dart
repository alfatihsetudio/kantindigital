import '../shared/auth/auth_session.dart';
import '../shared/constants/user_role.dart';

/// Guard sederhana berbasis AuthSession (token + role dari Laravel).
class RouteGuard {
  final AuthSession _session = AuthSession();

  bool get isAuthenticated => _session.isAuthenticated;
  UserRole? get role => _session.role;

  bool canAccessAdmin() => isAuthenticated && role == UserRole.admin;
  bool canAccessCashier() => isAuthenticated && role == UserRole.cashier;
  bool canAccessOperations() => isAuthenticated && role == UserRole.operations;
  bool canAccessManager() => isAuthenticated && role == UserRole.manager;
  bool canAccessSuperAdmin() => isAuthenticated && role == UserRole.superadmin;
}
