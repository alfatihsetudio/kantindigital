import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_digital/features/admin/auth/login_controller.dart';
import 'package:kantin_digital/features/admin/auth/login_service.dart';
import 'package:kantin_digital/shared/services/demo_session_manager.dart';

void main() {
  group('AdminLoginController Tests', () {
    setUp(() {
      DemoSessionManager.disableDemoMode();
    });

    test('Failed login with wrong password returns backend error and does NOT fallback to demo mode', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': false,
            'message': 'Email atau Password salah',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AdminAuthService(client: mockClient);
      final controller = AdminLoginController(service: service);

      String? navigatedRoute;
      final error = await controller.login(
        email: 'admin@gmail.com',
        password: 'wrongpassword',
        onNavigate: (route) {
          navigatedRoute = route;
        },
      );

      // Verify that it did NOT navigate to any route (did not login)
      expect(navigatedRoute, isNull);
      // Verify that demo mode was NOT enabled
      expect(DemoSessionManager.isDemoMode, isFalse);
      // Verify that error message is "Email atau Password salah"
      expect(error, equals('Email atau Password salah'));
    });

    test('Failed login with non-existent email returns backend error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'status': false,
            'message': 'Email atau Password salah',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AdminAuthService(client: mockClient);
      final controller = AdminLoginController(service: service);

      final error = await controller.login(
        email: 'unknown@example.com',
        password: 'anypassword',
        onNavigate: (_) {},
      );

      expect(DemoSessionManager.isDemoMode, isFalse);
      expect(error, equals('Email atau Password salah'));
    });
  });
}
