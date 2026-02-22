import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/notice_item_card.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_notices_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantAnnouncementsSection extends ConsumerWidget {
  const TenantAnnouncementsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesState = ref.watch(tenantNoticesProvider);
    final isLoading = noticesState.isLoading;
    final activeNotices = noticesState.activeNotices;

    // Show loading state
    if (isLoading && activeNotices.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Show latest 5 notices
    final displayNotices = activeNotices.take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.campaign, color: AppTheme.tenantColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Announcements${activeNotices.isEmpty ? '' : ' (${activeNotices.length})'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Notices list or empty state
            if (displayNotices.isEmpty)
              _buildEmptyState()
            else ...[
              ...displayNotices.map((noticeWithContext) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space name label
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.business,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            noticeWithContext.spaceName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notice card (without delete button for tenants)
                    NoticeItemCard(
                      notice: noticeWithContext.notice,
                      showDeleteButton: false, // Tenants can't delete
                    ),
                  ],
                );
              }),

              // View more indicator if there are more notices
              if (activeNotices.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: Text(
                      '+ ${activeNotices.length - 5} more announcement${activeNotices.length - 5 > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.textHint.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.textHint.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.campaign_outlined,
            size: 48,
            color: AppTheme.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'No announcements',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Your landlords haven\'t posted any announcements yet',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
