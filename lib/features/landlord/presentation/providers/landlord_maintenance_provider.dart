import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:apartment_app/features/tenant/data/models/maintenance_request_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/landlord_maintenance_repository.dart';

// State
class LandlordMaintenanceState {
  final List<MaintenanceRequest> requests;
  final MaintenanceRequestDetails? selectedRequest;
  final bool isLoading;
  final bool isLoadingDetails;
  final bool isUpdating;
  final String? error;

  const LandlordMaintenanceState({
    this.requests = const [],
    this.selectedRequest,
    this.isLoading = false,
    this.isLoadingDetails = false,
    this.isUpdating = false,
    this.error,
  });

  LandlordMaintenanceState copyWith({
    List<MaintenanceRequest>? requests,
    MaintenanceRequestDetails? selectedRequest,
    bool? isLoading,
    bool? isLoadingDetails,
    bool? isUpdating,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return LandlordMaintenanceState(
      requests: requests ?? this.requests,
      selectedRequest: clearSelected ? null : (selectedRequest ?? this.selectedRequest),
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isUpdating: isUpdating ?? this.isUpdating,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Computed properties
  List<MaintenanceRequest> get pendingRequests =>
      requests.where((r) => r.isPending).toList();

  List<MaintenanceRequest> get inProgressRequests =>
      requests.where((r) => r.isInProgress).toList();

  List<MaintenanceRequest> get completedRequests =>
      requests.where((r) => r.isCompleted).toList();

  bool get hasRequests => requests.isNotEmpty;
  bool get hasPendingRequests => pendingRequests.isNotEmpty;
}

// Notifier
class LandlordMaintenanceNotifier extends Notifier<LandlordMaintenanceState> {
  late final LandlordMaintenanceRepository _repository;

  @override
  LandlordMaintenanceState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = LandlordMaintenanceRepository(apiClient);

    return const LandlordMaintenanceState();
  }

  // 🆕 NEW: Load all requests from all landlord's spaces
  Future<void> loadAllSpacesRequests({String? status}) async {
    print('🛠️ [LANDLORD MAINTENANCE] Loading requests from ALL spaces');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final requests = await _repository.getAllSpacesRequests(status: status);
      print('🛠️ [LANDLORD MAINTENANCE] Loaded ${requests.length} requests from all spaces');

      state = state.copyWith(
        requests: requests,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ [LANDLORD MAINTENANCE] ApiException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ [LANDLORD MAINTENANCE] Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load requests',
      );
    }
  }

  // Load all requests for a space
  Future<void> loadSpaceRequests(String spaceId, {String? status}) async {
    print('🛠️ [LANDLORD MAINTENANCE] Loading requests for space: $spaceId');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final requests = await _repository.getSpaceRequests(
        spaceId: spaceId,
        status: status,
      );
      print('🛠️ [LANDLORD MAINTENANCE] Loaded ${requests.length} requests');

      state = state.copyWith(
        requests: requests,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ [LANDLORD MAINTENANCE] ApiException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ [LANDLORD MAINTENANCE] Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load requests',
      );
    }
  }

  // Load request details
  Future<void> loadRequestDetails(String requestId) async {
    print('🛠️ [LANDLORD MAINTENANCE] Loading details for: $requestId');
    state = state.copyWith(isLoadingDetails: true, clearError: true);

    try {
      final details = await _repository.getRequestDetails(requestId);
      print('🛠️ [LANDLORD MAINTENANCE] Loaded details with ${details.comments.length} comments');

      state = state.copyWith(
        selectedRequest: details,
        isLoadingDetails: false,
      );
    } on ApiException catch (e) {
      print('❌ [LANDLORD MAINTENANCE] ApiException: ${e.message}');
      state = state.copyWith(
        isLoadingDetails: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ [LANDLORD MAINTENANCE] Exception: $e');
      state = state.copyWith(
        isLoadingDetails: false,
        error: 'Failed to load request details',
      );
    }
  }

  // Update request status
  Future<void> updateStatus(String requestId, MaintenanceStatus newStatus) async {
    print('🛠️ [LANDLORD MAINTENANCE] Updating status for $requestId to ${newStatus.value}');
    state = state.copyWith(isUpdating: true, clearError: true);

    try {
      await _repository.updateStatus(
        requestId: requestId,
        status: newStatus,
      );
      print('🛠️ [LANDLORD MAINTENANCE] Status updated successfully');

      // Update in list
      final updatedRequests = state.requests.map((r) {
        if (r.id == requestId) {
          return MaintenanceRequest(
            id: r.id,
            category: r.category,
            customCategory: r.customCategory,
            title: r.title,
            description: r.description,
            images: r.images,
            status: newStatus,
            createdAt: r.createdAt,
            updatedAt: DateTime.now(),
            resolvedAt: newStatus == MaintenanceStatus.completed ? DateTime.now() : null,
            spaceId: r.spaceId,
            spaceName: r.spaceName,
            roomId: r.roomId,
            roomNumber: r.roomNumber,
            tenantId: r.tenantId,
            tenantFirstName: r.tenantFirstName,
            tenantLastName: r.tenantLastName,
            tenantEmail: r.tenantEmail,
            commentCount: r.commentCount,
          );
        }
        return r;
      }).toList();

      state = state.copyWith(
        requests: updatedRequests,
        isUpdating: false,
      );

      // Reload details if it's the selected one
      if (state.selectedRequest?.id == requestId) {
        await loadRequestDetails(requestId);
      }
    } on ApiException catch (e) {
      print('❌ [LANDLORD MAINTENANCE] ApiException: ${e.message}');
      state = state.copyWith(
        isUpdating: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      print('❌ [LANDLORD MAINTENANCE] Exception: $e');
      state = state.copyWith(
        isUpdating: false,
        error: 'Failed to update status',
      );
      rethrow;
    }
  }

  // Add comment
  Future<void> addComment(String requestId, String content) async {
    print('🛠️ [LANDLORD MAINTENANCE] Adding comment to: $requestId');

    try {
      final comment = await _repository.addComment(
        requestId: requestId,
        content: content,
      );
      print('🛠️ [LANDLORD MAINTENANCE] Comment added: ${comment.id}');

      // Update selected request if it's the current one
      if (state.selectedRequest?.id == requestId) {
        final updatedComments = [...state.selectedRequest!.comments, comment];
        final updatedRequest = MaintenanceRequestDetails(
          id: state.selectedRequest!.id,
          category: state.selectedRequest!.category,
          customCategory: state.selectedRequest!.customCategory,
          title: state.selectedRequest!.title,
          description: state.selectedRequest!.description,
          images: state.selectedRequest!.images,
          status: state.selectedRequest!.status,
          createdAt: state.selectedRequest!.createdAt,
          updatedAt: state.selectedRequest!.updatedAt,
          resolvedAt: state.selectedRequest!.resolvedAt,
          spaceId: state.selectedRequest!.spaceId,
          spaceName: state.selectedRequest!.spaceName,
          roomId: state.selectedRequest!.roomId,
          roomNumber: state.selectedRequest!.roomNumber,
          tenantId: state.selectedRequest!.tenantId,
          tenantFirstName: state.selectedRequest!.tenantFirstName,
          tenantLastName: state.selectedRequest!.tenantLastName,
          tenantEmail: state.selectedRequest!.tenantEmail,
          commentCount: updatedComments.length,
          comments: updatedComments,
        );

        state = state.copyWith(selectedRequest: updatedRequest);
      }
    } on ApiException catch (e) {
      print('❌ [LANDLORD MAINTENANCE] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [LANDLORD MAINTENANCE] Exception: $e');
      throw Exception('Failed to add comment');
    }
  }

  // Clear selected request
  void clearSelectedRequest() {
    state = state.copyWith(clearSelected: true);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final landlordMaintenanceProvider =
    NotifierProvider<LandlordMaintenanceNotifier, LandlordMaintenanceState>(
  LandlordMaintenanceNotifier.new,
);