import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/maintenance_request_model.dart';
import '../../data/repositories/maintenance_repository.dart';

// State
class MaintenanceState {
  final List<MaintenanceRequest> requests;
  final MaintenanceRequestDetails? selectedRequest;
  final bool isLoading;
  final bool isLoadingDetails;
  final bool isSubmitting;
  final String? error;

  const MaintenanceState({
    this.requests = const [],
    this.selectedRequest,
    this.isLoading = false,
    this.isLoadingDetails = false,
    this.isSubmitting = false,
    this.error,
  });

  MaintenanceState copyWith({
    List<MaintenanceRequest>? requests,
    MaintenanceRequestDetails? selectedRequest,
    bool? isLoading,
    bool? isLoadingDetails,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return MaintenanceState(
      requests: requests ?? this.requests,
      selectedRequest: clearSelected ? null : (selectedRequest ?? this.selectedRequest),
      isLoading: isLoading ?? this.isLoading,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
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
class MaintenanceNotifier extends Notifier<MaintenanceState> {
  late final MaintenanceRepository _repository;

  @override
  MaintenanceState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = MaintenanceRepository(apiClient);

    return const MaintenanceState();
  }

  // Load all requests
  Future<void> loadRequests() async {
    print('🛠️ [MAINTENANCE] Loading requests...');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final requests = await _repository.getMyRequests();
      print('🛠️ [MAINTENANCE] Loaded ${requests.length} requests');

      state = state.copyWith(
        requests: requests,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ [MAINTENANCE] ApiException: ${e.message}');
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ [MAINTENANCE] Exception: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load requests',
      );
    }
  }

  // Load request details
  Future<void> loadRequestDetails(String requestId) async {
    print('🛠️ [MAINTENANCE] Loading details for: $requestId');
    state = state.copyWith(isLoadingDetails: true, clearError: true);

    try {
      final details = await _repository.getRequestDetails(requestId);
      print('🛠️ [MAINTENANCE] Loaded details with ${details.comments.length} comments');

      state = state.copyWith(
        selectedRequest: details,
        isLoadingDetails: false,
      );
    } on ApiException catch (e) {
      print('❌ [MAINTENANCE] ApiException: ${e.message}');
      state = state.copyWith(
        isLoadingDetails: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ [MAINTENANCE] Exception: $e');
      state = state.copyWith(
        isLoadingDetails: false,
        error: 'Failed to load request details',
      );
    }
  }

  // Create new request
  Future<void> createRequest({
    required MaintenanceCategory category,
    String? customCategory,
    required String title,
    required String description,
    String? imageData,
  }) async {
    print('🛠️ [MAINTENANCE] Creating request: $title');
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final request = await _repository.createRequest(
        category: category,
        customCategory: customCategory,
        title: title,
        description: description,
        imageData: imageData,
      );
      print('🛠️ [MAINTENANCE] Request created: ${request.id}');

      // Add to list
      state = state.copyWith(
        requests: [request, ...state.requests],
        isSubmitting: false,
      );
    } on ApiException catch (e) {
      print('❌ [MAINTENANCE] ApiException: ${e.message}');
      state = state.copyWith(
        isSubmitting: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      print('❌ [MAINTENANCE] Exception: $e');
      state = state.copyWith(
        isSubmitting: false,
        error: 'Failed to create request',
      );
      rethrow;
    }
  }

  // Add comment
  Future<void> addComment(String requestId, String content) async {
    print('🛠️ [MAINTENANCE] Adding comment to: $requestId');

    try {
      final comment = await _repository.addComment(
        requestId: requestId,
        content: content,
      );
      print('🛠️ [MAINTENANCE] Comment added: ${comment.id}');

      // Update selected request if it's the current one
      if (state.selectedRequest?.id == requestId) {
        final updatedComments = [...state.selectedRequest!.comments, comment];
        final updatedRequest = MaintenanceRequestDetails(
          id: state.selectedRequest!.id,
          category: state.selectedRequest!.category,
          customCategory: state.selectedRequest!.customCategory,
          title: state.selectedRequest!.title,
          description: state.selectedRequest!.description,
          imageData: state.selectedRequest!.imageData,
          status: state.selectedRequest!.status,
          createdAt: state.selectedRequest!.createdAt,
          updatedAt: state.selectedRequest!.updatedAt,
          resolvedAt: state.selectedRequest!.resolvedAt,
          spaceId: state.selectedRequest!.spaceId,
          spaceName: state.selectedRequest!.spaceName,
          roomId: state.selectedRequest!.roomId,
          roomNumber: state.selectedRequest!.roomNumber,
          commentCount: updatedComments.length,
          comments: updatedComments,
        );

        state = state.copyWith(selectedRequest: updatedRequest);
      }
    } on ApiException catch (e) {
      print('❌ [MAINTENANCE] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [MAINTENANCE] Exception: $e');
      throw Exception('Failed to add comment');
    }
  }

  // Cancel request
  Future<void> cancelRequest(String requestId) async {
    print('🛠️ [MAINTENANCE] Cancelling request: $requestId');

    try {
      await _repository.cancelRequest(requestId);
      print('🛠️ [MAINTENANCE] Request cancelled');

      // Update in list
      final updatedRequests = state.requests.map((r) {
        if (r.id == requestId) {
          return MaintenanceRequest(
            id: r.id,
            category: r.category,
            customCategory: r.customCategory,
            title: r.title,
            description: r.description,
            imageData: r.imageData,
            status: MaintenanceStatus.cancelled,
            createdAt: r.createdAt,
            updatedAt: DateTime.now(),
            resolvedAt: r.resolvedAt,
            spaceId: r.spaceId,
            spaceName: r.spaceName,
            roomId: r.roomId,
            roomNumber: r.roomNumber,
            commentCount: r.commentCount,
          );
        }
        return r;
      }).toList();

      state = state.copyWith(requests: updatedRequests);

      // Reload details if it's the selected one
      if (state.selectedRequest?.id == requestId) {
        await loadRequestDetails(requestId);
      }
    } on ApiException catch (e) {
      print('❌ [MAINTENANCE] ApiException: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [MAINTENANCE] Exception: $e');
      throw Exception('Failed to cancel request');
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
final maintenanceProvider =
    NotifierProvider<MaintenanceNotifier, MaintenanceState>(
  MaintenanceNotifier.new,
);