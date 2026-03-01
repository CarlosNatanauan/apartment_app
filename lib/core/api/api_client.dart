import 'package:dio/dio.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import 'package:apartment_app/core/constants/app_constants.dart';
import 'api_response.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage;



  Future<ApiResponse<T>> postMultipart<T>(
    String path, {
    required FormData formData,
    T Function(dynamic)? fromJson,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
            // Do NOT set Content-Type manually to application/json for this call
          },
        ),
        onSendProgress: onSendProgress,
      );

      _checkAndThrowError(response);

      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      if (e.response == null) {
        throw ApiException('Network error. Please check your connection.');
      }
      rethrow;
    }
  }


  ApiClient(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Accept all status codes, handle errors manually
          return true;
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_loggingInterceptor());
  }

  // Auth Interceptor - Adds token to requests
  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    );
  }

  // Logging Interceptor - For debugging
  Interceptor _loggingInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ RESPONSE[${response.statusCode}] => DATA: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) {
        print('❌ DIO ERROR: ${error.message}');
        return handler.next(error);
      },
    );
  }

  // Helper method to extract error message from response
  String _extractErrorMessage(dynamic data, int statusCode) {
    String message = 'An error occurred';

    if (data is Map) {
      if (data['message'] != null) {
        if (data['message'] is List) {
          message = (data['message'] as List).join(', ');
        } else if (data['message'] is String) {
          message = data['message'];
        }
      }
    }

    // Fallback messages for common status codes
    if (message == 'An error occurred') {
      switch (statusCode) {
        case 401:
          message = 'Invalid email or password';
          break;
        case 403:
          message = 'Access forbidden';
          break;
        case 404:
          message = 'Resource not found';
          break;
        case 500:
        case 502:
        case 503:
          message = 'Server error. Please try again later.';
          break;
      }
    }

    return message;
  }

  // Helper method to check and throw error if needed
  void _checkAndThrowError(Response response) {
    final statusCode = response.statusCode;
    
    if (statusCode != null && statusCode >= 400) {
      final message = _extractErrorMessage(response.data, statusCode);
      print('⚠️ HTTP Error $statusCode: $message');
      
      // Clear token on 401
      if (statusCode == 401) {
        _storage.deleteToken();
      }
      
      throw ApiException(message, statusCode);
    }
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      
      // Check for errors AFTER getting response
      _checkAndThrowError(response);
      
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      // Network errors (no response from server)
      if (e.response == null) {
        throw ApiException('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      
      // Check for errors AFTER getting response
      _checkAndThrowError(response);
      
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      // Network errors (no response from server)
      if (e.response == null) {
        throw ApiException('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      
      // Check for errors AFTER getting response
      _checkAndThrowError(response);
      
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      // Network errors (no response from server)
      if (e.response == null) {
        throw ApiException('Network error. Please check your connection.');
      }
      rethrow;
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(path, data: data);
      
      // Check for errors AFTER getting response
      _checkAndThrowError(response);
      
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      // Network errors (no response from server)
      if (e.response == null) {
        throw ApiException('Network error. Please check your connection.');
      }
      rethrow;
    }
  }
}