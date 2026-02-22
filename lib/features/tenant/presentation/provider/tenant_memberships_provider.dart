import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/features/landlord/data/models/membership_model.dart';
import 'package:apartment_app/features/tenant/data/repositories/tenant_memberships_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// State
class TenantMembershipsState {
  final List<Membership> memberships;
  final bool isLoading;
  final String? error;

  const TenantMembershipsState({
    this.memberships = const [],
    this.isLoading = false,
    this.error,
  });

  TenantMembershipsState copyWith({
    List<Membership>? memberships,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TenantMembershipsState(
      memberships: memberships ?? this.memberships,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<Membership> get activeMemberships =>
      memberships.where((m) => m.isActive).toList();

  List<Membership> get pendingMemberships =>
      memberships.where((m) => m.isPending).toList();

  bool get hasActiveMemberships => activeMemberships.isNotEmpty;
  bool get hasPendingMemberships => pendingMemberships.isNotEmpty;
}

// Notifier
class TenantMembershipsNotifier extends Notifier<TenantMembershipsState> {
  late final TenantMembershipsRepository _repository;

  @override
  TenantMembershipsState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = TenantMembershipsRepository(apiClient);

    return const TenantMembershipsState();
  }

  // Load tenant memberships
  Future<void> loadMemberships() async {
    print('🟢 [TENANT PROVIDER] Starting loadMemberships...');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final memberships = await _repository.getMyMemberships();
      print('🟢 [TENANT PROVIDER] Got ${memberships.length} memberships');
      
      for (var m in memberships) {
        print('🟢 [TENANT PROVIDER] Membership: ${m.spaceName} - ${m.status} - Active rooms: ${m.activeRoomCount}');
      }
      
      state = state.copyWith(
        memberships: memberships,
        isLoading: false,
      );
      print('🟢 [TENANT PROVIDER] State updated with ${state.memberships.length} memberships');
    } on ApiException catch (e) {
      print('🔴 [TENANT PROVIDER] ApiException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('🔴 [TENANT PROVIDER] Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load memberships',
      );
    }
  }

  // Join a space
  Future<void> joinSpace(String joinCode) async {
    try {
      final membership = await _repository.joinSpace(joinCode);

      state = state.copyWith(
        memberships: [membership, ...state.memberships],
      );
    } on ApiException {
      rethrow;
    }
  }

  // Leave entire space (ends ALL leases + membership)
  Future<void> leaveSpace(String membershipId) async {
    try {
      await _repository.leaveSpace(membershipId);

      state = state.copyWith(
        memberships: state.memberships.where((m) => m.id != membershipId).toList(),
      );
    } on ApiException {
      rethrow;
    }
  }

  // 🆕 NEW: Leave a single room (ends ONE lease, membership stays ACTIVE)
  Future<void> leaveRoomLease({
    required String membershipId,
    required String leaseId,
  }) async {
    try {
      print('🟡 [TENANT PROVIDER] Leaving room lease: $leaseId');
      
      await _repository.leaveRoomLease(leaseId);
      
      print('✅ [TENANT PROVIDER] Room lease ended');
      
      // Reload memberships to get updated lease statuses
      await loadMemberships();
    } on ApiException catch (e) {
      print('🔴 [TENANT PROVIDER] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔴 [TENANT PROVIDER] Exception: $e');
      throw Exception('Failed to leave room: ${e.toString()}');
    }
  }

  // Request to join another room
  Future<void> requestRoomLease({
    required String membershipId,
    required String roomId,
  }) async {
    try {
      print('🟢 [TENANT PROVIDER] Requesting room lease...');
      
      final newLease = await _repository.requestRoomLease(
        membershipId: membershipId,
        roomId: roomId,
      );
      
      print('🟢 [TENANT PROVIDER] Room lease created: ${newLease.leaseId}');

      // Update the membership with the new lease
      final updatedMemberships = state.memberships.map((m) {
        if (m.id == membershipId) {
          print('🟢 [TENANT PROVIDER] Adding new lease to membership');
          return m.copyWith(
            roomLeases: [...m.roomLeases, newLease],
          );
        }
        return m;
      }).toList();

      state = state.copyWith(memberships: updatedMemberships);
      print('🟢 [TENANT PROVIDER] State updated with new lease');
    } on ApiException catch (e) {
      print('🔴 [TENANT PROVIDER] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      print('🔴 [TENANT PROVIDER] Exception: $e');
      throw Exception('Failed to request room: ${e.toString()}');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final tenantMembershipsProvider =
    NotifierProvider<TenantMembershipsNotifier, TenantMembershipsState>(
  TenantMembershipsNotifier.new,
);