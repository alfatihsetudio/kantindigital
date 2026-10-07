import 'package:flutter_test/flutter_test.dart';

bool isValidWhatsAppNumber(String phone) {
  final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  if (cleaned.isEmpty) return false;
  return RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{6,10}$').hasMatch(cleaned);
}

void main() {
  group('WhatsApp Phone Validation Tests', () {
    test('Valid Indonesian mobile numbers', () {
      expect(isValidWhatsAppNumber('08123456789'), isTrue); // 11 digits
      expect(isValidWhatsAppNumber('081234567890'), isTrue); // 12 digits
      expect(isValidWhatsAppNumber('0812-3456-7890'), isTrue); // with dash
      expect(isValidWhatsAppNumber('0812 3456 7890'), isTrue); // with space
      expect(isValidWhatsAppNumber('+6281234567890'), isTrue); // +62 format
      expect(isValidWhatsAppNumber('6281234567890'), isTrue); // 62 format
      expect(isValidWhatsAppNumber('085712345678'), isTrue); // Indosat
      expect(isValidWhatsAppNumber('087812345678'), isTrue); // XL
      expect(isValidWhatsAppNumber('089612345678'), isTrue); // Three
      expect(isValidWhatsAppNumber('088112345678'), isTrue); // Smartfren
    });

    test('Invalid numbers rejected', () {
      expect(isValidWhatsAppNumber(''), isFalse);
      expect(isValidWhatsAppNumber('abc'), isFalse);
      expect(isValidWhatsAppNumber('0211234567'), isFalse); // Landline
      expect(isValidWhatsAppNumber('08012345678'), isFalse); // 080 is invalid
      expect(isValidWhatsAppNumber('0812'), isFalse); // Too short
      expect(isValidWhatsAppNumber('0812345678901234'), isFalse); // Too long
      expect(isValidWhatsAppNumber('1234567890'), isFalse); // Missing 08/628
    });
  });
}
