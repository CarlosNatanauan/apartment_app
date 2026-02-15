import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import '../models/maintenance_request_model.dart';

class MaintenanceRepository {
  final ApiClient _apiClient;

  MaintenanceRepository(this._apiClient);

  // Create maintenance request
  Future<MaintenanceRequest> createRequest({
    required MaintenanceCategory category,
    String? customCategory,
    required String title,
    required String description,
    String? imageData,
  }) async {
    try {
      final requestData = {
        'category': category.value,
        if (customCategory != null && category == MaintenanceCategory.other)
          'customCategory': customCategory,
        'title': title,
        'description': description,
        if (imageData != null) 'imageData': imageData,
      };

      final response = await _apiClient.post(
        '/maintenance',
        data: requestData,
        fromJson: (data) => MaintenanceRequest.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to create maintenance request');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create maintenance request: ${e.toString()}');
    }
  }

  // Get my maintenance requests
  Future<List<MaintenanceRequest>> getMyRequests({
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final queryParams = {
        'limit': limit.toString(),
        if (cursor != null) 'cursor': cursor,
      };

      final response = await _apiClient.get(
        '/maintenance/my',
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

  // Get request details
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

  // Add comment to request
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

  // Cancel request (PENDING only)
  Future<void> cancelRequest(String requestId) async {
    try {
      final response = await _apiClient.post(
        '/maintenance/$requestId/cancel',
        data: {},
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to cancel request');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to cancel request: ${e.toString()}');
    }
  }
}