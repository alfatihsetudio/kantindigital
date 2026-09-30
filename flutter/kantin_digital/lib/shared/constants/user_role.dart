enum UserRole {
  admin,
  cashier,
  manager,
}

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
        return 'Admin/Operator';
      case UserRole.cashier:
        return 'Kasir/Pelayan';
      case UserRole.manager:
        return 'Pimpinan';
    }
  }
}
