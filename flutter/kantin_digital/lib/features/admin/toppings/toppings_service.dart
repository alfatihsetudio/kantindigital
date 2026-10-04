import '../../../core/network/api_client.dart';
import '../../../shared/models/topping_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class AdminToppingsService {
  final ApiClient _client = ApiClient();

  Future<List<ToppingModel>> getToppings() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getToppings();
    }
    final response = await _client.get('/toppings');
    final data = response['data'] as List;
    return data.map((json) => ToppingModel.fromJson(json)).toList();
  }

  Future<void> createTopping(Map<String, dynamic> body) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.createTopping(body);
      return;
    }
    await _client.post('/toppings', body: body);
  }

  Future<void> updateTopping(int id, Map<String, dynamic> body) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.updateTopping(id, body);
      return;
    }
    await _client.put('/toppings/$id', body: body);
  }

  Future<void> deleteTopping(int id) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.deleteTopping(id);
      return;
    }
    await _client.delete('/toppings/$id');
  }
}
