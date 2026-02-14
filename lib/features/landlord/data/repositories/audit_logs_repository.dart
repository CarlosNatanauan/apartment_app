import 'package:apartment_app/core/api/api_response.dart';
import 'package:dio/dio.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import 'package:apartment_app/core/constants/app_constants.dart';
import '../models/audit_log_model.dart';

class AuditLogPaginatedResponse {
  final List<AuditLog> logs;
  final String? nextCursor;
  final bool hasMore;

  AuditLogPaginatedResponse({
    required this.logs,
    this.nextCursor,
    this.hasMore = false,
  });
}

class AuditLogsRepository {
  final SecureStorage _storage;
  late final Dio _dio;

  AuditLogsRepository(this._storage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // Get audit logs for a space with pagination
  Future<AuditLogPaginatedResponse> getAuditLogs(
    String spaceId, {
    String? cursor,
    int limit = 20,
  }) async {
    try {
      // Get token
      final token = await _storage.getToken();
      
      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      print('📜 Fetching audit logs with params: $queryParams');

      // Make request directly with Dio to access full response
      final response = await _dio.get(
        '/spaces/$spaceId/audit',
        queryParameters: queryParams,
        options: Options(
          headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        ),
      );

      print('✅ Raw response status: ${response.statusCode}');

      // Check for errors
      if (response.statusCode != null && response.statusCode! >= 400) {
        final message = response.data['message'] ?? 'Failed to load audit logs';
        throw ApiException(message, response.statusCode!);
      }

      // Parse full response
      final responseData = response.data as Map<String, dynamic>;
      final logsData = responseData['data'] as List;
      final pageData = responseData['page'] as Map<String, dynamic>?;

      final logs = logsData
          .map((json) => AuditLog.fromJson(json as Map<String, dynamic>))
          .toList();

      final nextCursor = pageData?['nextCursor'] as String?;

      print('✅ Parsed ${logs.length} logs, nextCursor: $nextCursor');

      return AuditLogPaginatedResponse(
        logs: logs,
        nextCursor: nextCursor,
        hasMore: nextCursor != null,
      );
    } on DioException catch (e) {
      print('❌ Dio error: ${e.message}');
      if (e.response != null) {
        final message = e.response!.data['message'] ?? 'Failed to load audit logs';
        throw ApiException(message, e.response!.statusCode ?? 500);
      }
      throw ApiException('Network error. Please check your connection.');
    } on ApiException {
      rethrow;
    } catch (e) {
      print('❌ Repository error: $e');
      throw Exception('Failed to load audit logs: ${e.toString()}');
    }
  }
}