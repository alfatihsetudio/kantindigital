class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? errors;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  /// Parser fleksibel untuk response Laravel yang umum:
  /// - { "data": ... }
  /// - { "success": true, "message": "...", "data": ... }
  static ApiResponse<T> fromJson<T>(
    Map<String, dynamic> json, {
    required T Function(dynamic rawData) dataParser,
  }) {
    final dynamic rawData = json.containsKey('data') ? json['data'] : null;
    final bool success = json['success'] is bool ? json['success'] as bool : true;

    return ApiResponse<T>(
      success: success,
      message: json['message']?.toString(),
      data: rawData == null ? null : dataParser(rawData),
      errors: json['errors'] is Map<String, dynamic> ? json['errors'] as Map<String, dynamic> : null,
    );
  }
}

