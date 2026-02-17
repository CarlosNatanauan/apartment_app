import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/tenant/data/models/maintenance_request_model.dart';

class LandlordMaintenanceRepository {
  final ApiClient _apiClient;

  LandlordMaintenanceRepository(this._apiClient);

  // 🆕 NEW: Get all maintenance requests from all spaces owned by landlord
  Future<List<MaintenanceRequest>> getAllSpacesRequests({
    String? status,
    int limit = 100, // Higher limit for all spaces
    String? cursor,
  }) async {
    try {
      // We'll need to fetch all spaces first, then fetch maintenance for each
      // Or better: create a new backend endpoint /maintenance/all
      // For now, let's use a simpler approach: fetch from each space and combine
      
      final queryParams = {
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (cursor != null) 'cursor': cursor,
      };

      // ✅ FIX: Changed endpoint to avoid route conflict
      final response = await _apiClient.get(
        '/landlord/maintenance/all',
        queryParameters: queryParams,
        fromJson: (data) {
          if (data is List) {
            return data
                .map((json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return <MaintenanceRequest>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load maintenance requests');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load all maintenance requests: ${e.toString()}');
    }
  }

  // Get all maintenance requests for a space
  Future<List<MaintenanceRequest>> getSpaceRequests({
    required String spaceId,
    String? status,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (status != null) 'status': status,
        if (cursor != null) 'cursor': cursor,
      };

      final response = await _apiClient.get(
        '/spaces/$spaceId/maintenance',
        queryParameters: queryParams,
        fromJson: (data) {
          if (data is List) {
            return data
                .map((json) => MaintenanceRequest.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return <MaintenanceRequest>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load maintenance requests');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load maintenance requests: ${e.toString()}');
    }
  }

  // Get request details (same endpoint as tenant)
  Future<MaintenanceRequestDetails> getRequestDetails(String requestId) async {
    try {
      final response = await _apiClient.get(
        '/maintenance/$requestId',
        fromJson: (data) => MaintenanceRequestDetails.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load request details');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load request details: ${e.toString()}');
    }
  }

  // Update request status
  Future<void> updateStatus({
    required String requestId,
    required MaintenanceStatus status,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/maintenance/$requestId/status',
        data: {'status': status.value},
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to update status');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update status: ${e.toString()}');
    }
  }

  // Add comment to request (same endpoint as tenant)
  Future<MaintenanceComment> addComment({
    required String requestId,
    required String content,
  }) async {
    try {
      final response = await _apiClient.post(
        '/maintenance/$requestId/comments',
        data: {'content': content},
        fromJson: (data) => MaintenanceComment.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to add comment');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to add comment: ${e.toString()}');
    }
  }
}