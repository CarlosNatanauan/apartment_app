import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/core/utils/currency_formatter.dart';
import '../models/membership_model.dart';

class MembershipsRepository {
  final ApiClient _apiClient;

  MembershipsRepository(this._apiClient);

  // Get pending requests for a space
  Future<List<Membership>> getPendingRequests(String spaceId) async {
    try {
      final response = await _apiClient.get(
        '/spaces/$spaceId/requests',
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => Membership.fromJson(json)).toList();
          }
          return <Membership>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load pending requests');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load pending requests: ${e.toString()}');
    }
  }

  // Get active members for a space
  Future<List<Membership>> getActiveMembers(String spaceId) async {
    try {
      final response = await _apiClient.get(
        '/spaces/$spaceId/members',
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => Membership.fromJson(json)).toList();
          }
          return <Membership>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load active members');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load active members: ${e.toString()}');
    }
  }

  // Approve a pending request and assign room
  // 🆕 UPDATED: Now includes optional rent fields
  Future<Membership> approveMembership({
    required String membershipId,
    required String roomId,
    int? monthlyRent,
    DateTime? rentStartDate,
    int? paymentDueDay,
  }) async {
    try {
      // Build request body
      final Map<String, dynamic> requestData = {
        'roomId': roomId,
      };

      // Add rent fields if provided
      if (monthlyRent != null) {
        requestData['monthlyRent'] = monthlyRent;
      }
      if (rentStartDate != null) {
        requestData['rentStartDate'] = DateFormatter.formatForApi(rentStartDate);
      }
      if (paymentDueDay != null) {
        requestData['paymentDueDay'] = paymentDueDay;
      }

      final response = await _apiClient.post(
        '/memberships/$membershipId/approve',
        data: requestData,
        fromJson: (data) => Membership.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to approve membership');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to approve membership: ${e.toString()}');
    }
  }

  // Reject a pending request
  Future<void> rejectMembership(String membershipId) async {
    try {
      final response = await _apiClient.post(
        '/memberships/$membershipId/reject',
        data: {},
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to reject membership');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to reject membership: ${e.toString()}');
    }
  }

  // Move member to different room
  Future<Membership> moveMembership(String membershipId, String roomId) async {
    try {
      final response = await _apiClient.post(
        '/memberships/$membershipId/move',
        data: {'roomId': roomId},
        fromJson: (data) => Membership.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to move membership');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to move membership: ${e.toString()}');
    }
  }

  // Remove member (kick out)
  Future<void> removeMembership(String membershipId) async {
    try {
      final response = await _apiClient.post(
        '/memberships/$membershipId/remove',
        data: {},
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to remove membership');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to remove membership: ${e.toString()}');
    }
  }
}