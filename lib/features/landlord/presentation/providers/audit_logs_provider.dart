import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/audit_log_model.dart';
import '../../data/repositories/audit_logs_repository.dart';

// Audit logs state with pagination
class AuditLogsState {
  final List<AuditLog> logs;
  final bool isLoading;
  final bool isLoadingMore;
  final String? nextCursor;
  final bool hasMore;
  final String? error;

  AuditLogsState({
    this.logs = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.nextCursor,
    this.hasMore = false,
    this.error,
  });

  AuditLogsState copyWith({
    List<AuditLog>? logs,
    bool? isLoading,
    bool? isLoadingMore,
    String? nextCursor,
    bool? hasMore,
    String? error,
    bool clearError = false,
    bool clearCursor = false,
  }) {
    return AuditLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Audit logs notifier
class AuditLogsNotifier extends Notifier<AuditLogsState> {
  late final AuditLogsRepository _repository;

  @override
  AuditLogsState build() {
    // ✅ Pass SecureStorage instead of ApiClient
    final storage = ref.read(secureStorageProvider);
    _repository = AuditLogsRepository(storage);
    
    return AuditLogsState();
  }

  // Load initial page of audit logs
  Future<void> loadAuditLogs(String spaceId) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCursor: true,
    );

    try {
      print('📜 Loading audit logs for space: $spaceId');
      
      final response = await _repository.getAuditLogs(spaceId);
      
      print('✅ Loaded ${response.logs.length} audit logs');
      print('   Next cursor: ${response.nextCursor}');
      print('   Has more: ${response.hasMore}');
      
      state = state.copyWith(
        logs: response.logs,
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load audit logs (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load audit logs (Exception): $e');
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load audit logs',
      );
    }
  }

  // Load more audit logs (pagination)
  Future<void> loadMoreAuditLogs(String spaceId) async {
    // Don't load if already loading or no more data
    if (state.isLoadingMore || !state.hasMore || state.nextCursor == null) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, clearError: true);

    try {
      print('📜 Loading more audit logs, cursor: ${state.nextCursor}');
      
      final response = await _repository.getAuditLogs(
        spaceId,
        cursor: state.nextCursor,
      );
      
      print('✅ Loaded ${response.logs.length} more audit logs');
      
      // Append new logs to existing ones
      final allLogs = [...state.logs, ...response.logs];
      
      state = state.copyWith(
        logs: allLogs,
        nextCursor: response.nextCursor,
        hasMore: response.hasMore,
        isLoadingMore: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load more audit logs (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoadingMore: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load more audit logs (Exception): $e');
      
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more audit logs',
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Providers
final secureStorageProvider = Provider((ref) => SecureStorage());

final auditLogsProvider = NotifierProvider<AuditLogsNotifier, AuditLogsState>(() {
  return AuditLogsNotifier();
});