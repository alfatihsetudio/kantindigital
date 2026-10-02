import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../shared/models/user_model.dart';

class AdminAuthService {
  final http.Client _http;

  AdminAuthService({http.Client? client}) : _http = client ?? http.Client();

  /// Ekspektasi response:
  /// { "status": true, "message": "...", "data": { "token": "...", "user": { ... }, "tenant": { ... } } }
  Future<({String token, UserModel user, TenantModel? tenant})> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/login');
    final response = await _http.post(
      uri,
      headers: {
        'Accept': 'application/json',
      },
      body: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Login gagal (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['status'] != true) {
      throw Exception(body['message']?.toString() ?? 'Login gagal');
    }

    final data = body['data'] as Map<String, dynamic>;
    final token = (data['token'] ?? '').toString();
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    final tenantJson = data['tenant'] as Map<String, dynamic>?;
    final tenant = tenantJson != null ? TenantModel.fromJson(tenantJson) : null;

    if (token.isEmpty) {
      throw Exception('Token tidak ditemukan pada response login');
    }

    return (token: token, user: user, tenant: tenant);
  }
}

