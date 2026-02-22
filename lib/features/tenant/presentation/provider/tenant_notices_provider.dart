import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/features/landlord/data/models/notice_models.dart';
import 'package:apartment_app/features/landlord/data/repositories/notices_repository.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_memberships_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Notice with space context
class SpaceNoticeWithContext {
  final SpaceNotice notice;
  final String spaceName;
  final String spaceId;

  SpaceNoticeWithContext({
    required this.notice,
    required this.spaceName,
    required this.spaceId,
  });
}

// Tenant Notices State
class TenantNoticesState {
  final List<SpaceNoticeWithContext> notices;
  final bool isLoading;
  final String? error;

  TenantNoticesState({
    this.notices = const [],
    this.isLoading = false,
    this.error,
  });

  TenantNoticesState copyWith({
    List<SpaceNoticeWithContext>? notices,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return TenantNoticesState(
      notices: notices ?? this.notices,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Get active (non-expired) notices
  List<SpaceNoticeWithContext> get activeNotices =>
      notices.where((n) => !n.notice.isExpired).toList();

  // Get latest N notices
  List<SpaceNoticeWithContext> getLatest(int count) =>
      activeNotices.take(count).toList();

  // Group by space
  Map<String, List<SpaceNoticeWithContext>> get noticesBySpace {
    final Map<String, List<SpaceNoticeWithContext>> grouped = {};
    
    for (final noticeWithContext in activeNotices) {
      grouped.putIfAbsent(noticeWithContext.spaceName, () => [])
          .add(noticeWithContext);
    }
    
    return grouped;
  }
}

// Tenant Notices Notifier
class TenantNoticesNotifier extends Notifier<TenantNoticesState> {
  late final NoticesRepository _repository;

  @override
  TenantNoticesState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = NoticesRepository(apiClient);
    
    return TenantNoticesState();
  }

  // Load notices from all tenant's active spaces
  Future<void> loadAllNotices() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      print('📢 Loading notices for all tenant spaces');
      
      // Get tenant's active memberships
      final membershipsState = ref.read(tenantMembershipsProvider);
      final activeMemberships = membershipsState.activeMemberships;
      
      print('📢 Found ${activeMemberships.length} active memberships');

      // Fetch notices from each space
      final List<SpaceNoticeWithContext> allNotices = [];
      
      for (final membership in activeMemberships) {
        if (membership.spaceId == null) continue;
        
        try {
          final spaceNotices = await _repository.getNotices(membership.spaceId!);
          
          // Wrap each notice with space context
          for (final notice in spaceNotices) {
            allNotices.add(SpaceNoticeWithContext(
              notice: notice,
              spaceName: membership.spaceName ?? 'Space',
              spaceId: membership.spaceId!,
            ));
          }
          
          print('📢 Loaded ${spaceNotices.length} notices from ${membership.spaceName}');
        } catch (e) {
          print('⚠️ Failed to load notices from ${membership.spaceName}: $e');
          // Continue loading from other spaces even if one fails
        }
      }

      // Sort by creation date (newest first)
      allNotices.sort((a, b) => b.notice.createdAt.compareTo(a.notice.createdAt));
      
      print('✅ Loaded total ${allNotices.length} notices');
      
      state = state.copyWith(
        notices: allNotices,
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
        error: 'Failed to load announcements',
      );
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final tenantNoticesProvider =
    NotifierProvider<TenantNoticesNotifier, TenantNoticesState>(() {
  return TenantNoticesNotifier();
});