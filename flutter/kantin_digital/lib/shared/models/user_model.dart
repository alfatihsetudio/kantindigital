import '../constants/user_role.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final UserRole? role;
  final bool mustChangePassword;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.mustChangePassword = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: UserRoleX.fromApi(json['role']?.toString()),
      mustChangePassword: _parseBool(json['must_change_password']),
    );
  }

  UserModel copyWith({bool? mustChangePassword}) => UserModel(
    id: id,
    name: name,
    email: email,
    role: role,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  static bool _parseBool(dynamic value) =>
      value == true || value == 1 || value == '1' || value == 'true';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role?.toApi(),
      'must_change_password': mustChangePassword,
    };
  }
}
