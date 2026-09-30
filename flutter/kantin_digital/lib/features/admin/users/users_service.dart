import '../../../core/network/api_client.dart';
import '../../../shared/models/user_model.dart';

class AdminUsersService {
  final ApiClient _client = ApiClient();

  Future<List<UserModel>> getUsers() async {
    final response = await _client.get('/users');
    final data = response['data'] as List;
    return data.map((json) => UserModel.fromJson(json)).toList();
  }

  Future<void> createUser(Map<String, dynamic> body) async {
    await _client.post('/users', body: body);
  }

  Future<void> updateUser(int id, Map<String, dynamic> body) async {
    body['_method'] = 'PUT';
    await _client.post('/users/$id', body: body);
  }

  Future<void> deleteUser(int id) async {
    await _client.post('/users/$id', body: {'_method': 'DELETE'});
  }
}
