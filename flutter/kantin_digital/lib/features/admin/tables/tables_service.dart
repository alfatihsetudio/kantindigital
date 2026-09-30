import '../../../core/network/api_client.dart';
import '../../../shared/models/table_model.dart';

class AdminTablesService {
  final ApiClient _client = ApiClient();

  Future<List<TableModel>> getTables() async {
    final response = await _client.get('/tables');
    final data = response['data'] as List;
    return data.map((json) => TableModel.fromJson(json)).toList();
  }

  Future<void> createTable(String code) async {
    await _client.post('/tables', body: {'code': code});
  }

  Future<void> updateTable(int id, String code) async {
    await _client.post('/tables/$id', body: {'code': code, '_method': 'PUT'});
  }

  Future<void> deleteTable(int id) async {
    await _client.post('/tables/$id', body: {'_method': 'DELETE'});
  }
}
