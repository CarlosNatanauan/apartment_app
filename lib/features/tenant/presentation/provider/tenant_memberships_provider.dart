import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/features/landlord/data/models/membership_model.dart';
import 'package:apartment_app/features/tenant/data/repositories/tenant_memberships_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// =======================
// State
// =======================
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

  // Computed properties
  List<Membership> get activeMemberships =>
      memberships.where((m) => m.isActive).toList();

  List<Membership> get pendingMemberships =>
      memberships.where((m) => m.isPending).toList();

  bool get hasActiveMemberships => activeMemberships.isNotEmpty;
  bool get hasPendingMemberships => pendingMemberships.isNotEmpty;
}

// =======================
// Notifier
// =======================
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
      print('🟢 [TENANT PROVIDER] Membership: ${m.spaceName} - ${m.status}');
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

  // Leave a space
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

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// =======================
// Provider
// =======================
final tenantMembershipsProvider =
    NotifierProvider<TenantMembershipsNotifier, TenantMembershipsState>(
  TenantMembershipsNotifier.new,
);
