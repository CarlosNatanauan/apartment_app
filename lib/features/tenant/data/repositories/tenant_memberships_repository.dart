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
          List<dynamic> items;

          if (data is Map && data.containsKey('data')) {
            items = data['data'] as List? ?? [];
          } else if (data is List) {
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

  // Leave entire space (ends ALL room leases + ends membership)
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

  // 🆕 NEW: Leave a single room (ends ONE lease, membership stays ACTIVE)
  Future<void> leaveRoomLease(String leaseId) async {
    try {
      print('🟡 Leaving room lease: $leaseId');
      
      final response = await _apiClient.post(
        '/room-leases/$leaseId/end',
        data: {},
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to leave room');
      }

      print('✅ Room lease ended successfully');
    } on ApiException {
      rethrow;
    } catch (e) {
      print('🔴 Error leaving room: $e');
      throw Exception('Failed to leave room: ${e.toString()}');
    }
  }

  // Request to join another room in a space
  Future<RoomLease> requestRoomLease({
    required String membershipId,
    required String roomId,
  }) async {
    try {
      print('🟢 Requesting room lease: membership=$membershipId, room=$roomId');
      
      final response = await _apiClient.post(
        '/memberships/$membershipId/room-leases',
        data: {'roomId': roomId},
        fromJson: (data) {
          print('🟢 Room lease request response: $data');
          // Backend returns: { ok: true, data: { leaseId, status, roomId } }
          if (data is Map && data.containsKey('data')) {
            return RoomLease.fromJson(data['data'] as Map<String, dynamic>);
          }
          return RoomLease.fromJson(data as Map<String, dynamic>);
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to request room lease');
      }

      print('🟢 Room lease created: ${response.data!.leaseId}');
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      print('🔴 Error requesting room lease: $e');
      throw Exception('Failed to request room: ${e.toString()}');
    }
  }
}