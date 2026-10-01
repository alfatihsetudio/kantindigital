import '../../../core/network/api_client.dart';
import '../../../shared/models/topping_model.dart';

class AdminToppingsService {
  final ApiClient _client = ApiClient();

  Future<List<ToppingModel>> getToppings() async {
    final response = await _client.get('/toppings');
    final data = response['data'] as List;
    return data.map((json) => ToppingModel.fromJson(json)).toList();
  }

  Future<void> createTopping(Map<String, dynamic> body) async {
    await _client.post('/toppings', body: body);
  }

  Future<void> updateTopping(int id, Map<String, dynamic> body) async {
    await _client.put('/toppings/$id', body: body);
  }

  Future<void> deleteTopping(int id) async {
    await _client.delete('/toppings/$id');
  }
}
