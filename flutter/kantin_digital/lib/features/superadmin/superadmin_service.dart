import '../../core/network/api_client.dart';
import '../../shared/models/managed_tenant_model.dart';

class SuperAdminService {
  final ApiClient _client = ApiClient();

  Future<List<ManagedTenantModel>> fetchTenants() async {
    final response = await _client.get('/superadmin/tenants');
    final data = response['data'] as List;
    return data.map((json) => ManagedTenantModel.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> createTenant(
    Map<String, dynamic> data,
  ) async {
    final response = await _client.post('/superadmin/tenants', body: data);
    final accounts = response['initial_accounts'] as List;
    return accounts.cast<Map<String, dynamic>>();
  }

  Future<void> updateTenant(int id, Map<String, dynamic> data) async {
    await _client.put('/superadmin/tenants/$id', body: data);
  }
}
