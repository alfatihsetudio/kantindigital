import '../constants/user_role.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final UserRole? role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRoleX.fromApi(json['role']?.toString()),
    );
  }
}

