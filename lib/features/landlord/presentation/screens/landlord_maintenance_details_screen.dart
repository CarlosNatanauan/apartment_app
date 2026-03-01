import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/core/constants/app_constants.dart';
import 'package:apartment_app/features/landlord/presentation/providers/landlord_maintenance_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/dialogs/update_status_dialog.dart';
import 'package:apartment_app/features/tenant/data/models/maintenance_request_model.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/status_badge.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LandlordMaintenanceDetailsScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String requestId;
  final String? spaceName;

  const LandlordMaintenanceDetailsScreen({
    super.key,
    required this.spaceId,
    required this.requestId,
    this.spaceName,
  });

  @override
  ConsumerState<LandlordMaintenanceDetailsScreen> createState() =>
      _LandlordMaintenanceDetailsScreenState();
}

class _LandlordMaintenanceDetailsScreenState
    extends ConsumerState<LandlordMaintenanceDetailsScreen> {
  final _commentController = TextEditingController();
  bool _isAddingComment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(landlordMaintenanceProvider.notifier)
          .loadRequestDetails(widget.requestId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateStatus() async {
    final request = ref.read(landlordMaintenanceProvider).selectedRequest;
    if (request == null) return;

    final newStatus = await showDialog<MaintenanceStatus>(
      context: context,
      builder: (context) => UpdateStatusDialog(currentStatus: request.status),
    );

    if (newStatus == null || !mounted) return;

    try {
      await ref
          .read(landlordMaintenanceProvider.notifier)
          .updateStatus(widget.requestId, newStatus);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
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

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isAddingComment = true);

    try {
      await ref
          .read(landlordMaintenanceProvider.notifier)
          .addComment(widget.requestId, _commentController.text.trim());

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
    final state = ref.watch(landlordMaintenanceProvider);
    final request = state.selectedRequest;
    final isLoading = state.isLoadingDetails;
    final isUpdating = state.isUpdating;

    if (isLoading || request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Request Details'),
            if (widget.spaceName != null)
              Text(
                widget.spaceName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Update Status',
            onPressed: isUpdating ? null : _handleUpdateStatus,
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
                // Status Badge & Tenant Info
                Row(
                  children: [
                    StatusBadge(status: request.status),
                    const Spacer(),
                    Text(
                      _formatDate(request.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Tenant Info Card
                Card(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E40AF), AppTheme.landlordColor],
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        // Frosted avatar
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              request.tenantFirstName?[0].toUpperCase() ?? 'T',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name & email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.tenantFullName ?? 'Tenant',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if (request.tenantEmail != null)
                                Text(
                                  request.tenantEmail!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Room pill
                        if (request.roomNumber != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room_outlined,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  'Unit ${request.roomNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
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
                _buildInfoSection('Title', request.title, Icons.title_outlined),

                const SizedBox(height: 16),

                // Description
                _buildInfoSection(
                  'Description',
                  request.description,
                  Icons.description_outlined,
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
                                style: Theme.of(context).textTheme.titleMedium
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                  backgroundColor: AppTheme.landlordColor,
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
                    color: AppTheme.landlordColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppTheme.landlordColor),
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
            Text(content, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
