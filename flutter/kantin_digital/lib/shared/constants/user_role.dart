enum UserRole { admin, cashier, operations, manager }

extension UserRoleX on UserRole {
  static UserRole? fromApi(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase()) {
      case 'admin':
      case 'operator':
        return UserRole.admin;
      case 'cashier':
      case 'kasir':
      case 'pelayan':
        return UserRole.cashier;
      case 'operations':
      case 'operasional':
      case 'produksi':
        return UserRole.operations;
      case 'manager':
      case 'pimpinan':
        return UserRole.manager;
      default:
        return null;
    }
  }

  String toApi() => name;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Owner/Pemilik';
      case UserRole.cashier:
        return 'Kasir/Pelayan';
      case UserRole.operations:
        return 'Operasional';
      case UserRole.manager:
        return 'Pimpinan';
    }
  }
}
