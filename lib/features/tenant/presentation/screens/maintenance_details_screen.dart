import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/core/constants/app_constants.dart';
import 'package:apartment_app/features/tenant/presentation/provider/maintenance_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/status_badge.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MaintenanceDetailsScreen extends ConsumerStatefulWidget {
  final String requestId;

  const MaintenanceDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<MaintenanceDetailsScreen> createState() =>
      _MaintenanceDetailsScreenState();
}

class _MaintenanceDetailsScreenState
    extends ConsumerState<MaintenanceDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(maintenanceProvider.notifier).loadRequestDetails(widget.requestId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isAddingComment = true);

    try {
      await ref.read(maintenanceProvider.notifier).addComment(
            widget.requestId,
            _commentController.text.trim(),
          );

      _commentController.clear();
      setState(() => _isAddingComment = false);

      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } on ApiException catch (e) {
      setState(() => _isAddingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isAddingComment = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceProvider);
    final request = state.selectedRequest;
    final isLoading = state.isLoadingDetails;

    if (isLoading || request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          if (request.canCancel)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: 'Cancel Request',
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Request'),
                    content: const Text(
                      'Are you sure you want to cancel this request?\n\nThis action cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('No'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Yes, Cancel'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && mounted) {
                  try {
                    await ref
                        .read(maintenanceProvider.notifier)
                        .cancelRequest(widget.requestId);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request cancelled successfully'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      context.pop();
                    }
                  } on ApiException catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.message),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Request Details Section
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Status Badge & date
                Row(
                  children: [
                    StatusBadge(status: request.status),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 12,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(request.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Category
                _buildInfoSection(
                  'Category',
                  request.categoryDisplay,
                  Icons.category_outlined,
                ),

                const SizedBox(height: 16),

                // Title
                _buildInfoSection(
                  'Title',
                  request.title,
                  Icons.title_outlined,
                ),

                const SizedBox(height: 16),

                // Description
                _buildInfoSection(
                  'Description',
                  request.description,
                  Icons.description_outlined,
                ),

                const SizedBox(height: 16),

                // Space & Room
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.tenantColor
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.apartment_outlined,
                                  size: 16, color: AppTheme.tenantColor),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Location',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.business_outlined,
                                size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                request.spaceName ?? '',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.meeting_room_outlined,
                                size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Unit ${request.roomNumber}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Images (if present)
                if (request.hasImages) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.photo_library, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Photos (${request.images.length})',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: request.images.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final img = request.images[index];
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    '${AppConstants.baseUrl}${img.imagePath}',
                                    width: 200,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Comments Section
                Text(
                  'Comments (${request.comments.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),

                if (request.comments.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...request.comments.map((comment) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: comment.author.isLandlord
                                      ? AppTheme.landlordColor
                                      : AppTheme.tenantColor,
                                  child: Text(
                                    comment.author.firstName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.author.fullName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        comment.author.role,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: comment.author.isLandlord
                                                  ? AppTheme.landlordColor
                                                  : AppTheme.tenantColor,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _formatDate(comment.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              comment.content,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 80),
              ],
            ),
          ),

          // Comment Input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isAddingComment,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.tenantColor,
                  child: _isAddingComment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.send, size: 20),
                          color: Colors.white,
                          onPressed: _handleAddComment,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.tenantColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.tenantColor),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}