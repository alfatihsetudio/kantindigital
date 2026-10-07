import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/models/tenant_model.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/services/tenant_service.dart';

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
        if (TenantService.currentSubdomain != null)
          'X-Tenant': TenantService.currentSubdomain!,
      },
      body: {'email': email, 'password': password},
    );

    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        body = decoded;
      }
    } catch (_) {}

    if (response.statusCode != 200) {
      final msg = body?['message']?.toString();
      if (msg != null && msg.trim().isNotEmpty) {
        throw Exception(msg.trim());
      }
      if (response.statusCode == 401) {
        throw Exception('Email atau Password salah');
      }
      throw Exception('Login gagal (${response.statusCode})');
    }

    if (body == null || body['status'] != true) {
      throw Exception(body?['message']?.toString() ?? 'Login gagal');
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
