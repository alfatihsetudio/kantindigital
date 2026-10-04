import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class AdminUsersService {
  final ApiClient _client = ApiClient();

  Future<List<UserModel>> getUsers() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getUsers();
    }
    final response = await _client.get('/users');
    final data = response['data'] as List;
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<void> createUser(Map<String, dynamic> body) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.createUser(body);
      return;
    }
    await _client.post('/users', body: body);
  }

  Future<void> updateUser(int id, Map<String, dynamic> body) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.updateUser(id, body);
      return;
    }
    await _client.put('/users/$id', body: body);
  }

  Future<void> deleteUser(int id) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.deleteUser(id);
      return;
    }
    await _client.delete('/users/$id');
  }
}
