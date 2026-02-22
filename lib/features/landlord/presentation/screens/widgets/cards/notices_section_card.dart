import 'package:apartment_app/features/landlord/data/models/notice_models.dart';
import 'package:apartment_app/features/landlord/presentation/providers/notices_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/notice_item_card.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/dialogs/create_notice_dialog.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NoticesSectionCard extends ConsumerWidget {
  final String spaceId;
  final String spaceName;

  const NoticesSectionCard({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticesState = ref.watch(noticesProvider);
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

    // Show latest 3 notices
    final displayNotices = activeNotices.take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.campaign, color: AppTheme.landlordColor),
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
                // New Announcement button
                ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.landlordColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: const Size(0, 0),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'New',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Notices list or empty state
            if (displayNotices.isEmpty)
              _buildEmptyState(context)
            else ...[
              ...displayNotices.map((notice) => NoticeItemCard(
                notice: notice,
                onDelete: () => _confirmDelete(context, ref, notice),
              )),
              
              // View All button if more than 3
              if (activeNotices.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to full notices list screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Full notices screen coming soon!'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.landlordColor,
                        side: const BorderSide(color: AppTheme.landlordColor),
                      ),
                      icon: const Icon(Icons.list, size: 18),
                      label: Text(
                        'View All Announcements (${activeNotices.length})',
                        style: const TextStyle(fontSize: 13),
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

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.textHint.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.textHint.withOpacity(0.2),
        ),
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
            'No announcements yet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Post announcements to notify all tenants',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final result = await showCreateNoticeDialog(
      context: context,
      spaceId: spaceId,
    );
    
    // Dialog handles refresh via provider
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, SpaceNotice notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Announcement?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notice.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This announcement will be removed for all tenants.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              try {
                await ref.read(noticesProvider.notifier).deleteNotice(
                  spaceId: spaceId,
                  noticeId: notice.noticeId,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Announcement deleted'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}