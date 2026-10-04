class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic raw;

  const ApiException({required this.message, this.statusCode, this.raw});

  String get userMessage {
    if (statusCode == 429) {
      return 'Pesanan terlalu sering dikirim dari jaringan ini. '
          'Untuk mencegah spam, silakan tunggu sebentar sebelum mencoba lagi. '
          'Pesanan belum dibuat.';
    }
    if (statusCode == 422) {
      return 'Pesanan belum dapat diproses. Periksa kembali jumlah menu, '
          'jumlah per menu, dan topping yang dipilih.';
    }
    return message;
  }

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
