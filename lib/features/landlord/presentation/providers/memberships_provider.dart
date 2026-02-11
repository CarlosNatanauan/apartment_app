import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/membership_model.dart';
import '../../data/repositories/memberships_repository.dart';

// Memberships state
class MembershipsState {
  final List<Membership> pendingRequests;
  final List<Membership> activeMembers;
  final bool isLoadingPending;
  final bool isLoadingActive;
  final String? error;

  MembershipsState({
    this.pendingRequests = const [],
    this.activeMembers = const [],
    this.isLoadingPending = false,
    this.isLoadingActive = false,
    this.error,
  });

  MembershipsState copyWith({
    List<Membership>? pendingRequests,
    List<Membership>? activeMembers,
    bool? isLoadingPending,
    bool? isLoadingActive,
    String? error,
    bool clearError = false,
  }) {
    return MembershipsState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeMembers: activeMembers ?? this.activeMembers,
      isLoadingPending: isLoadingPending ?? this.isLoadingPending,
      isLoadingActive: isLoadingActive ?? this.isLoadingActive,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Memberships notifier
class MembershipsNotifier extends Notifier<MembershipsState> {
  late final MembershipsRepository _repository;

  @override
  MembershipsState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = MembershipsRepository(apiClient);
    
    return MembershipsState();
  }

  // Load pending requests
  Future<void> loadPendingRequests(String spaceId) async {
    state = state.copyWith(isLoadingPending: true, clearError: true);

    try {
      print('📋 Loading pending requests for space: $spaceId');
      
      final requests = await _repository.getPendingRequests(spaceId);
      
      print('✅ Loaded ${requests.length} pending requests');
      
      state = state.copyWith(
        pendingRequests: requests,
        isLoadingPending: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load pending requests (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoadingPending: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load pending requests (Exception): $e');
      
      state = state.copyWith(
        isLoadingPending: false,
        error: 'Failed to load pending requests',
      );
    }
  }

  // Load active members
  Future<void> loadActiveMembers(String spaceId) async {
    state = state.copyWith(isLoadingActive: true, clearError: true);

    try {
      print('👥 Loading active members for space: $spaceId');
      
      final members = await _repository.getActiveMembers(spaceId);
      
      print('✅ Loaded ${members.length} active members');
      
      state = state.copyWith(
        activeMembers: members,
        isLoadingActive: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load active members (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoadingActive: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load active members (Exception): $e');
      
      state = state.copyWith(
        isLoadingActive: false,
        error: 'Failed to load active members',
      );
    }
  }

  // Approve membership and assign room
  Future<bool> approveMembership(String membershipId, String roomId, String spaceId) async {
    try {
      print('✅ Approving membership: $membershipId, room: $roomId');
      
      // Call approve API (returns minimal response)
      await _repository.approveMembership(membershipId, roomId);
      
      print('✅ Membership approved');
      
      // Remove from pending list
      final updatedPending = state.pendingRequests
          .where((m) => m.id != membershipId)
          .toList();
      
      state = state.copyWith(pendingRequests: updatedPending);
      
      // ✅ Reload active members to get complete data with user email and room number
      await loadActiveMembers(spaceId);
      
      return true;
    } on ApiException catch (e) {
      print('❌ Failed to approve membership (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to approve membership (Exception): $e');
      
      state = state.copyWith(error: 'Failed to approve membership');
      rethrow;
    }
  }

  // Reject membership
  Future<bool> rejectMembership(String membershipId) async {
    try {
      print('❌ Rejecting membership: $membershipId');
      
      await _repository.rejectMembership(membershipId);
      
      print('✅ Membership rejected');
      
      // Remove from pending list
      final updatedPending = state.pendingRequests
          .where((m) => m.id != membershipId)
          .toList();
      
      state = state.copyWith(pendingRequests: updatedPending);
      
      return true;
    } on ApiException catch (e) {
      print('❌ Failed to reject membership (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to reject membership (Exception): $e');
      
      state = state.copyWith(error: 'Failed to reject membership');
      rethrow;
    }
  }

  // Move member to different room
  Future<bool> moveMembership(String membershipId, String roomId, String spaceId) async {
    try {
      print('🚚 Moving membership: $membershipId to room: $roomId');
      
      // Call move API (returns minimal response)
      await _repository.moveMembership(membershipId, roomId);
      
      print('✅ Membership moved');
      
      // ✅ Reload active members to get complete updated data
      await loadActiveMembers(spaceId);
      
      return true;
    } on ApiException catch (e) {
      print('❌ Failed to move membership (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to move membership (Exception): $e');
      
      state = state.copyWith(error: 'Failed to move membership');
      rethrow;
    }
  }

  // Remove member (kick out)
  Future<bool> removeMembership(String membershipId) async {
    try {
      print('🗑️ Removing membership: $membershipId');
      
      await _repository.removeMembership(membershipId);
      
      print('✅ Membership removed');
      
      // Remove from active list
      final updatedActive = state.activeMembers
          .where((m) => m.id != membershipId)
          .toList();
      
      state = state.copyWith(activeMembers: updatedActive);
      
      return true;
    } on ApiException catch (e) {
      print('❌ Failed to remove membership (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to remove membership (Exception): $e');
      
      state = state.copyWith(error: 'Failed to remove membership');
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final membershipsProvider = NotifierProvider<MembershipsNotifier, MembershipsState>(() {
  return MembershipsNotifier();
});