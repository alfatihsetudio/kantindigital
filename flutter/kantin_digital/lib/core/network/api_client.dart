import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/app_config.dart';
import '../utils/logger.dart';
import '../../shared/auth/auth_session.dart';
import '../../shared/services/tenant_service.dart';
import '../../shared/services/demo_session_manager.dart';
import 'api_exception.dart';
import 'api_interceptor.dart';

class ApiClient {
  final http.Client _http;
  final List<ApiInterceptor> _interceptors;

  ApiClient({
    http.Client? httpClient,
    List<ApiInterceptor> interceptors = const [],
  }) : _http = httpClient ?? http.Client(),
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
    final tenantSubdomain = AuthSession().tenantSubdomain ?? TenantService.currentSubdomain;
    if (tenantSubdomain != null && tenantSubdomain.isNotEmpty) {
      headers['X-Tenant'] = tenantSubdomain;
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

  bool _isAlwaysRealApi(String path) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    final basePath = clean.contains('?') ? clean.split('?').first : clean;
    return basePath == 'check-subdomain' ||
        basePath.startsWith('register-store') ||
        basePath.contains('showcase-stores') ||
        basePath.startsWith('tenants/public');
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (DemoSessionManager.isDemoMode && !_isAlwaysRealApi(path)) {
      return _handleDemo('GET', path, queryParameters: queryParameters);
    }

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
    if (DemoSessionManager.isDemoMode && !_isAlwaysRealApi(path)) {
      return _handleDemo('POST', path, body: body, queryParameters: queryParameters);
    }

    final uri = _buildUri(path, queryParameters);
    final request = http.Request('POST', uri);
    request.headers.addAll(await _defaultHeaders());
    if (body != null) request.body = jsonEncode(body);

    final applied = await _applyInterceptors(request);
    final streamed = await _http.send(applied);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (DemoSessionManager.isDemoMode && !_isAlwaysRealApi(path)) {
      return _handleDemo('PUT', path, body: body, queryParameters: queryParameters);
    }

    final uri = _buildUri(path, queryParameters);
    final request = http.Request('PUT', uri);
    request.headers.addAll(await _defaultHeaders());
    if (body != null) request.body = jsonEncode(body);

    final applied = await _applyInterceptors(request);
    final streamed = await _http.send(applied);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (DemoSessionManager.isDemoMode && !_isAlwaysRealApi(path)) {
      return _handleDemo('DELETE', path, queryParameters: queryParameters);
    }

    final uri = _buildUri(path, queryParameters);
    final request = http.Request('DELETE', uri);
    request.headers.addAll(await _defaultHeaders());

    final applied = await _applyInterceptors(request);
    final streamed = await _http.send(applied);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    String? fileField,
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
    Map<String, dynamic>? queryParameters,
  }) async {
    if (DemoSessionManager.isDemoMode && !_isAlwaysRealApi(path)) {
      return _handleDemo('POST', path, fields: fields, queryParameters: queryParameters);
    }

    final uri = _buildUri(path, queryParameters);
    final request = http.MultipartRequest('POST', uri);

    final headers = await _defaultHeaders();
    headers.remove('Content-Type');
    request.headers.addAll(headers);
    request.fields.addAll(fields);

    if (fileField != null && fileBytes != null && filename != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: filename,
          contentType: contentType == null
              ? null
              : _parseMediaType(contentType),
        ),
      );
    }

    final applied = await _applyInterceptors(request);
    final streamed = await _http.send(applied);
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  MediaType _parseMediaType(String contentType) {
    final parts = contentType.split('/');
    if (parts.length != 2) return MediaType('application', 'octet-stream');
    return MediaType(parts[0], parts[1]);
  }

  dynamic _handleResponse(http.Response response) {
    AppLogger.debug(
      'HTTP ${response.request?.method} ${response.request?.url} -> ${response.statusCode}',
    );

    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message =
        _extractErrorMessage(decoded) ?? 'Terjadi kesalahan pada server';
    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      raw: decoded,
    );
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null) return decoded['message'].toString();
      if (decoded['error'] != null) return decoded['error'].toString();
    }
    if (decoded is String && decoded.isNotEmpty) return decoded;
    return null;
  }

  /// Interceptor Lokal untuk Mode Demo (Terisolasi di browser client)
  dynamic _handleDemo(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? fields,
  }) {
    final clean = path.startsWith('/') ? path.substring(1) : path;
    AppLogger.debug('DemoInterceptor: $method /$clean');

    // 1. STATS (Admin & Manager)
    if (clean.contains('stats')) {
      return {'status': true, 'data': DemoSessionManager.getMockStats()};
    }

    // 2. KATEGORI
    if (clean == 'categories' && method == 'GET') {
      return {
        'status': true,
        'data': DemoSessionManager.getCategories().map((c) => {
          'id': c.id,
          'name': c.name,
          'is_active': c.isActive,
        }).toList(),
      };
    }

    if (clean == 'categories' && method == 'POST') {
      final name = (body?['name'] ?? fields?['name'] ?? 'Kategori Baru').toString();
      final cat = DemoSessionManager.createCategory(name);
      return {
        'status': true,
        'message': 'Kategori berhasil ditambahkan',
        'data': {'id': cat.id, 'name': cat.name, 'is_active': cat.isActive},
      };
    }

    final catToggleMatch = RegExp(r'^categories/(\d+)/toggle$').firstMatch(clean);
    if (catToggleMatch != null && method == 'POST') {
      final id = int.parse(catToggleMatch.group(1)!);
      final cat = DemoSessionManager.toggleCategory(id);
      return {
        'status': true,
        'message': 'Status kategori berhasil diubah',
        'data': {'id': cat.id, 'name': cat.name, 'is_active': cat.isActive},
      };
    }

    final catMatch = RegExp(r'^categories/(\d+)$').firstMatch(clean);
    if (catMatch != null) {
      final id = int.parse(catMatch.group(1)!);
      if (method == 'PUT') {
        final name = (body?['name'] ?? fields?['name'] ?? '').toString();
        final cat = DemoSessionManager.updateCategory(id, name);
        return {
          'status': true,
          'message': 'Kategori berhasil diperbarui',
          'data': {'id': cat.id, 'name': cat.name, 'is_active': cat.isActive},
        };
      }
      if (method == 'DELETE') {
        DemoSessionManager.deleteCategory(id);
        return {'status': true, 'message': 'Kategori berhasil dihapus'};
      }
    }

    // 3. MENUS
    if (clean == 'menus' && method == 'GET') {
      return {
        'status': true,
        'data': DemoSessionManager.getMenus().map((m) => {
          'id': m.id,
          'code': m.code,
          'name': m.name,
          'category_name': m.categoryName,
          'price': m.price,
          'image_url': m.imageUrl,
          'description': m.description,
          'is_available': m.isAvailable,
        }).toList(),
      };
    }

    if (clean == 'menus' && method == 'POST') {
      final data = <String, dynamic>{...?body, ...?fields};
      final menu = DemoSessionManager.createMenu(data);
      return {
        'status': true,
        'message': 'Menu berhasil dibuat',
        'data': {'id': menu.id, 'name': menu.name},
      };
    }

    final menuMatch = RegExp(r'^menus/(\d+)$').firstMatch(clean);
    if (menuMatch != null) {
      final id = int.parse(menuMatch.group(1)!);
      if (method == 'PUT' || method == 'POST') {
        final data = <String, dynamic>{...?body, ...?fields};
        final menu = DemoSessionManager.updateMenu(id, data);
        return {
          'status': true,
          'message': 'Menu berhasil diperbarui',
          'data': {'id': menu.id, 'name': menu.name},
        };
      }
      if (method == 'DELETE') {
        DemoSessionManager.deleteMenu(id);
        return {'status': true, 'message': 'Menu berhasil dihapus'};
      }
    }

    // 4. TOPPINGS
    if (clean.startsWith('toppings') && method == 'GET') {
      return {
        'status': true,
        'data': DemoSessionManager.getToppings().map((t) => {
          'id': t.id,
          'name': t.name,
          'price': t.price,
          'quantity': t.quantity,
        }).toList(),
      };
    }

    if (clean == 'toppings' && method == 'POST') {
      final data = <String, dynamic>{...?body, ...?fields};
      final top = DemoSessionManager.createTopping(data);
      return {
        'status': true,
        'message': 'Topping berhasil dibuat',
        'data': {'id': top.id, 'name': top.name, 'price': top.price},
      };
    }

    final toppingMatch = RegExp(r'^toppings/(\d+)$').firstMatch(clean);
    if (toppingMatch != null) {
      final id = int.parse(toppingMatch.group(1)!);
      if (method == 'PUT') {
        final data = <String, dynamic>{...?body, ...?fields};
        final top = DemoSessionManager.updateTopping(id, data);
        return {
          'status': true,
          'message': 'Topping berhasil diperbarui',
          'data': {'id': top.id, 'name': top.name, 'price': top.price},
        };
      }
      if (method == 'DELETE') {
        DemoSessionManager.deleteTopping(id);
        return {'status': true, 'message': 'Topping berhasil dihapus'};
      }
    }

    // 5. TABLES
    if (clean == 'tables' && method == 'GET') {
      return {
        'status': true,
        'data': DemoSessionManager.getTables().map((t) => {
          'id': t.id,
          'code': t.code,
          'name': t.name,
          'is_occupied': t.isOccupied,
        }).toList(),
      };
    }

    if (clean == 'tables' && method == 'POST') {
      final code = (body?['code'] ?? fields?['code'] ?? '99').toString();
      final table = DemoSessionManager.createTable(code);
      return {
        'status': true,
        'message': 'Meja berhasil ditambahkan',
        'data': {'id': table.id, 'code': table.code, 'name': table.name, 'is_occupied': table.isOccupied},
      };
    }

    final tableMatch = RegExp(r'^tables/(\d+)$').firstMatch(clean);
    if (tableMatch != null) {
      final id = int.parse(tableMatch.group(1)!);
      if (method == 'PUT') {
        final code = (body?['code'] ?? fields?['code'] ?? '').toString();
        final table = DemoSessionManager.updateTable(id, code);
        return {
          'status': true,
          'message': 'Meja berhasil diperbarui',
          'data': {'id': table.id, 'code': table.code, 'name': table.name, 'is_occupied': table.isOccupied},
        };
      }
      if (method == 'DELETE') {
        DemoSessionManager.deleteTable(id);
        return {'status': true, 'message': 'Meja berhasil dihapus'};
      }
    }

    // 6. USERS / STAFF
    if (clean == 'users' && method == 'GET') {
      return {
        'status': true,
        'data': DemoSessionManager.getUsers().map((u) => u.toJson()).toList(),
      };
    }

    if (clean == 'users' && method == 'POST') {
      final data = <String, dynamic>{...?body, ...?fields};
      final user = DemoSessionManager.createUser(data);
      return {
        'status': true,
        'message': 'Pengguna berhasil ditambahkan',
        'data': user.toJson(),
      };
    }

    final userMatch = RegExp(r'^users/(\d+)$').firstMatch(clean);
    if (userMatch != null) {
      final id = int.parse(userMatch.group(1)!);
      if (method == 'PUT') {
        final data = <String, dynamic>{...?body, ...?fields};
        final user = DemoSessionManager.updateUser(id, data);
        return {
          'status': true,
          'message': 'Pengguna berhasil diperbarui',
          'data': user.toJson(),
        };
      }
      if (method == 'DELETE') {
        DemoSessionManager.deleteUser(id);
        return {'status': true, 'message': 'Pengguna berhasil dihapus'};
      }
    }

    // 7. QRIS SETTING
    if (clean == 'qris-setting' && method == 'GET') {
      return {
        'status': true,
        'data': DemoSessionManager.demoQrisSetting.toJson(),
      };
    }

    if (clean == 'qris-setting' && method == 'POST') {
      final data = <String, dynamic>{...?body, ...?fields};
      final setting = DemoSessionManager.updateQrisSetting(
        merchantName: (data['merchant_name'] ?? 'DEMO RESTO & CAFE').toString(),
        merchantCity: (data['merchant_city'] ?? 'JAKARTA').toString(),
        whatsappNumber: (data['whatsapp_number'] ?? '6287771262100').toString(),
        basePayload: (data['base_payload'] ?? '').toString(),
        isActive: data['is_active'] != false && data['is_active'] != '0',
      );
      return {
        'status': true,
        'message': 'Pengaturan QRIS berhasil disimpan',
        'data': setting.toJson(),
      };
    }

    // 8. TENANT PROFILE
    if ((clean == 'tenant/update' || clean == 'tenant') && method == 'POST') {
      final data = <String, dynamic>{...?body, ...?fields};
      DemoSessionManager.updateTenantProfile(data);
      return {
        'status': true,
        'message': 'Profil kantin & logo berhasil disimpan!',
        'data': DemoSessionManager.demoTenant.toJson(),
      };
    }

    // 9. CHANGE PASSWORD & EMAIL
    if (clean == 'change-password') {
      return {'status': true, 'message': 'Password berhasil diubah (Mode Demo)'};
    }
    if (clean == 'change-email') {
      return {'status': true, 'message': 'Email berhasil diubah (Mode Demo)'};
    }

    // 10. ORDERS
    if (clean.startsWith('cashier/orders') || clean == 'orders') {
      if (method == 'GET') {
        final status = queryParameters?['status']?.toString();
        final list = DemoSessionManager.getCashierOrders(status: status);
        return {
          'status': true,
          'data': list.map((o) => {
            'id': o.id,
            'code': o.code,
            'customer_name': o.customerName,
            'customer_phone': o.customerPhone,
            'status': o.status,
            'payment_method': 'qris',
            'total_amount': o.totalAmount,
            'created_at': DateTime.now().toIso8601String(),
            'order_type': o.orderType,
            'delivery_address': o.deliveryAddress,
            'table': {'id': 1, 'code': o.tableCode, 'name': 'Meja ${o.tableCode}'},
            'items': o.items.map((i) => {
              'menu_name': i.menuName,
              'quantity': i.quantity,
              'price': i.price,
              'notes': i.notes,
              'toppings': i.toppings.map((t) => {
                'topping_name': t.toppingName,
                'topping_price': t.toppingPrice,
                'quantity': t.quantity,
              }).toList(),
            }).toList(),
          }).toList(),
        };
      }
      if (method == 'POST') {
        final items = (body?['items'] as List?) ?? [];
        final code = DemoSessionManager.createManualOrder(
          tableCode: (body?['table_code'] ?? '01').toString(),
          customerName: (body?['customer_name'] ?? '').toString(),
          customerPhone: (body?['customer_phone'] ?? '').toString(),
          items: items,
        );
        return {
          'status': true,
          'message': 'Pesanan berhasil dibuat',
          'data': {'code': code},
        };
      }
    }

    final orderStatusMatch = RegExp(r'^orders/(\d+)/status$').firstMatch(clean);
    if (orderStatusMatch != null && method == 'POST') {
      final id = int.parse(orderStatusMatch.group(1)!);
      final newStatus = (body?['status'] ?? '').toString();
      DemoSessionManager.updateOrderStatus(id, newStatus);
      return {'status': true, 'message': 'Status berhasil diubah'};
    }

    if (clean == 'check-subdomain') {
      final sub = (queryParameters?['subdomain'] ?? '').toString().toLowerCase().trim();
      final reserved = [
        'www', 'api', 'admin', 'superadmin', 'ekasir', 'kasirdigital', 'demo', 'staging',
        'mail', 'app', 'system', 'root', 'login', 'pos', 'dashboard', 'static', 'assets',
        'cdn', 'test', 'dev', 'support', 'help', 'manager', 'cashier', 'kitchen', 'owner',
        'billing', 'auth', 'portal'
      ];
      if (sub.length < 3) {
        return {
          'status': true,
          'available': false,
          'subdomain': sub,
          'message': 'Subdomain minimal harus 3 karakter.',
        };
      }
      if (reserved.contains(sub)) {
        return {
          'status': true,
          'available': false,
          'subdomain': sub,
          'message': "Subdomain '$sub' merupakan kata kunci sistem dan tidak dapat digunakan.",
        };
      }
      return {
        'status': true,
        'available': true,
        'subdomain': sub,
        'message': "Subdomain '$sub.ekasir.my.id' tersedia!",
      };
    }

    if (clean.startsWith('register-store/status/')) {
      final code = clean.replaceFirst('register-store/status/', '');
      return {
        'status': true,
        'message': 'Status invoice $code',
        'data': {
          'invoice_code': code,
          'status': 'UNPAID',
          'is_paid': false,
        }
      };
    }

    if (clean.startsWith('register-store')) {
      final storeName = (body?['store_name'] ?? 'Toko Saya').toString();
      final sub = (body?['subdomain'] ?? 'tokosaya').toString();
      final owner = (body?['owner_name'] ?? 'Pemilik').toString();
      final email = (body?['owner_email'] ?? 'admin@ekasir.my.id').toString();
      final inv = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      return {
        'status': true,
        'message': 'Pendaftaran toko berhasil!',
        'data': {
          'invoice': {
            'code': inv,
            'amount': 30000,
            'status': 'unpaid',
          },
          'qris': {
            'payload': '00020101021126570011ID.DANA.WWW011893600915303557205402090355720540303UMI51440014ID.CO.QRIS.WWW0215ID10266058542500303UMI5204581253033605802ID5910Say Coffee6011Kab. Serang6105421176304AB0C',
            'merchant_name': 'Say Coffee',
            'merchant_city': 'Kab. Serang',
            'whatsapp_number': '087771262100',
          },
          'store_name': storeName,
          'subdomain': sub,
          'store_url': 'https://$sub.ekasir.my.id',
          'login_url': 'https://$sub.ekasir.my.id/#/admin/login',
          'owner': {
            'name': owner,
            'email': email,
          }
        }
      };
    }

    // Default fallback
    return {'status': true, 'message': 'success', 'data': {}};
  }
}
