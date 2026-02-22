import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notice_models.dart';
import '../../data/repositories/notices_repository.dart';

// Notices state
class NoticesState {
  final List<SpaceNotice> notices;
  final bool isLoading;
  final String? error;

  NoticesState({
    this.notices = const [],
    this.isLoading = false,
    this.error,
  });

  NoticesState copyWith({
    List<SpaceNotice>? notices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NoticesState(
      notices: notices ?? this.notices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Filter only active (non-expired) notices
  List<SpaceNotice> get activeNotices =>
      notices.where((n) => !n.isExpired).toList();
  
  // Get latest N notices
  List<SpaceNotice> getLatest(int count) =>
      activeNotices.take(count).toList();
}

// Notices notifier
class NoticesNotifier extends Notifier<NoticesState> {
  late final NoticesRepository _repository;

  @override
  NoticesState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = NoticesRepository(apiClient);
    
    return NoticesState();
  }

  // Load notices for a space
  Future<void> loadNotices(String spaceId) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      print('📢 Loading notices for space: $spaceId');
      
      final notices = await _repository.getNotices(spaceId);
      
      print('✅ Loaded ${notices.length} notices');
      
      state = state.copyWith(
        notices: notices,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load notices (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load notices (Exception): $e');
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notices',
      );
    }
  }

  // Create a new notice
  Future<void> createNotice({
    required String spaceId,
    required String title,
    required String content,
    DateTime? expiresAt,
  }) async {
    try {
      print('📝 Creating notice...');
      
      final newNotice = await _repository.createNotice(
        spaceId: spaceId,
        title: title,
        content: content,
        expiresAt: expiresAt,
      );
      
      print('✅ Notice created');
      
      // Add to list at the beginning (most recent first)
      state = state.copyWith(
        notices: [newNotice, ...state.notices],
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create notice: ${e.toString()}');
    }
  }

  // Delete a notice
  Future<void> deleteNotice({
    required String spaceId,
    required String noticeId,
  }) async {
    try {
      print('🗑️ Deleting notice: $noticeId');
      
      await _repository.deleteNotice(
        spaceId: spaceId,
        noticeId: noticeId,
      );
      
      print('✅ Notice deleted');
      
      // Remove from list
      final updatedNotices = state.notices
          .where((n) => n.noticeId != noticeId)
          .toList();
      
      state = state.copyWith(notices: updatedNotices);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete notice: ${e.toString()}');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final noticesProvider = NotifierProvider<NoticesNotifier, NoticesState>(() {
  return NoticesNotifier();
});