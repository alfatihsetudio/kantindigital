import '../../../shared/models/user_model.dart';
import 'users_service.dart';

class AdminUsersController {
  final AdminUsersService _service = AdminUsersService();

  Future<List<UserModel>> fetchUsers() => _service.getUsers();
  Future<void> addUser(Map<String, dynamic> data) => _service.createUser(data);
  Future<void> editUser(int id, Map<String, dynamic> data) => _service.updateUser(id, data);
  Future<void> deleteUser(int id) => _service.deleteUser(id);
}
