import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/logger.dart';
import '../../shared/auth/auth_session.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';

class ApiClient {
  final http.Client _http;
  final List<ApiInterceptor> _interceptors;

  ApiClient({
    http.Client? httpClient,
    List<ApiInterceptor> interceptors = const [],
  })  : _http = httpClient ?? http.Client(),
        _interceptors = interceptors;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = AppConfig.apiBaseUrl;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$base/$cleanPath');
    if (queryParameters == null || queryParameters.isEmpty) return uri;

    return uri.replace(
      queryParameters: queryParameters.map((k, v) => MapEntry(k, v.toString())),
    );
  }

  Future<Map<String, String>> _defaultHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final token = AuthSession().token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<http.BaseRequest> _applyInterceptors(http.BaseRequest request) async {
    var current = request;
    for (final interceptor in _interceptors) {
      current = await interceptor.onRequest(current);
    }
    return current;
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final request = http.Request('GET', uri);
    request.headers.addAll(await _defaultHeaders());

    final applied = await _applyInterceptors(request);
    final streamed = await _http.send(applied);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final request = http.Request('POST', uri);
    request.headers.addAll(await _defaultHeaders());
    if (body != null) request.body = jsonEncode(body);

    final applied = await _applyInterceptors(request);
    final streamed = await _http.send(applied);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    AppLogger.debug('HTTP ${response.request?.method} ${response.request?.url} -> ${response.statusCode}');

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = _extractErrorMessage(decoded) ?? 'Terjadi kesalahan pada server';
    throw ApiException(statusCode: response.statusCode, message: message, raw: decoded);
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null) return decoded['message'].toString();
      if (decoded['error'] != null) return decoded['error'].toString();
    }
    if (decoded is String && decoded.isNotEmpty) return decoded;
    return null;
  }
}

