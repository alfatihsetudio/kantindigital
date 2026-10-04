import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_digital/core/network/api_exception.dart';

void main() {
  group('ApiException userMessage', () {
    test('explains order rate limiting in customer-friendly language', () {
      const exception = ApiException(
        statusCode: 429,
        message: 'Too Many Attempts.',
      );

      expect(exception.userMessage, contains('silakan tunggu sebentar'));
      expect(exception.userMessage, contains('Pesanan belum dibuat'));
    });

    test('explains rejected order validation', () {
      const exception = ApiException(
        statusCode: 422,
        message: 'The items field is invalid.',
      );

      expect(exception.userMessage, contains('Periksa kembali jumlah menu'));
    });

    test('preserves the server message for other errors', () {
      const exception = ApiException(
        statusCode: 500,
        message: 'Server unavailable',
      );

      expect(exception.userMessage, 'Server unavailable');
    });
  });
}
