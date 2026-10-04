import '../../../core/network/api_client.dart';
import '../../../shared/models/table_model.dart';
import '../../../shared/services/demo_session_manager.dart';

class AdminTablesService {
  final ApiClient _client = ApiClient();

  Future<List<TableModel>> getTables() async {
    if (DemoSessionManager.isDemoMode) {
      return DemoSessionManager.getTables();
    }

    final response = await _client.get('/tables');
    final data = response['data'] as List;
    return data.map((json) => TableModel.fromJson(json)).toList();
  }

  Future<void> createTable(String code) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.createTable(code);
      return;
    }
    await _client.post('/tables', body: {'code': code});
  }

  Future<void> updateTable(int id, String code) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.updateTable(id, code);
      return;
    }
    await _client.put('/tables/$id', body: {'code': code});
  }

  Future<void> deleteTable(int id) async {
    if (DemoSessionManager.isDemoMode) {
      DemoSessionManager.deleteTable(id);
      return;
    }
    await _client.delete('/tables/$id');
  }
}
