class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic raw;

  const ApiException({
    required this.message,
    this.statusCode,
    this.raw,
  });

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

