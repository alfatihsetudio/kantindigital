import 'package:http/http.dart' as http;

typedef TokenProvider = Future<String?> Function();

abstract class ApiInterceptor {
  Future<http.BaseRequest> onRequest(http.BaseRequest request);
}

class AuthInterceptor implements ApiInterceptor {
  final TokenProvider tokenProvider;

  AuthInterceptor(this.tokenProvider);

  @override
  Future<http.BaseRequest> onRequest(http.BaseRequest request) async {
    final token = await tokenProvider();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }
}
