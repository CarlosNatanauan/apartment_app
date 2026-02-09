class ApiResponse<T> {
  final bool ok;
  final T? data;
  final String? message;
  final Map<String, dynamic>? page;

  ApiResponse({
    required this.ok,
    this.data,
    this.message,
    this.page,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      ok: json['ok'] ?? false,
      data: fromJsonT != null && json['data'] != null 
          ? fromJsonT(json['data']) 
          : json['data'] as T?,
      message: json['message'] as String?,
      page: json['page'] as Map<String, dynamic>?,
    );
  }

  // Helper for checking success
  bool get isSuccess => ok && data != null;
}

// Exception class for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message; // ✅ Just return the message, no prefix
}