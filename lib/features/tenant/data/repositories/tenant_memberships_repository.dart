import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/data/models/membership_model.dart';

class TenantMembershipsRepository {
  final ApiClient _apiClient;

  TenantMembershipsRepository(this._apiClient);

  // Get tenant's own memberships
  Future<List<Membership>> getMyMemberships() async {
    try {
      final response = await _apiClient.get(
        '/memberships/me',
        fromJson: (data) {
          // Handle both cases: data is array OR data is wrapped in "data" field
          List<dynamic> items;

          if (data is Map && data.containsKey('data')) {
            // Backend wrapped in { ok: true, data: [...] }
            items = data['data'] as List? ?? [];
          } else if (data is List) {
            // Direct array
            items = data;
          } else {
            print('🔴 Unexpected data format: ${data.runtimeType}');
            return <Membership>[];
          }

          print('🔵 Parsing ${items.length} memberships');
          return items.map((json) => Membership.fromJson(json)).toList();
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load memberships');
      }

      return response.data!;
    } catch (e) {
      print('🔴 Error loading memberships: $e');
      rethrow;
    }
  }

  // Join a space using join code
  Future<Membership> joinSpace(String joinCode) async {
    try {
      final response = await _apiClient.post(
        '/spaces/join',
        data: {'joinCode': joinCode.trim().toUpperCase()},
        fromJson: (data) => Membership.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to join space');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to join space: ${e.toString()}');
    }
  }

  // Leave a space
  Future<void> leaveSpace(String membershipId) async {
    try {
      final response = await _apiClient.post(
        '/memberships/$membershipId/leave',
        data: {},
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to leave space');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to leave space: ${e.toString()}');
    }
  }
}
