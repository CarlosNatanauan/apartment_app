import 'package:apartment_app/features/tenant/data/models/maintenance_request_model.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/status_badge.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MaintenanceRequestCard extends StatelessWidget {
  final MaintenanceRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;

  const MaintenanceRequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onCancel,
  });

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
      return DateFormat('MMM d').format(date);
    }
  }

  IconData _getCategoryIcon() {
    switch (request.category) {
      case MaintenanceCategory.plumbing:
        return Icons.plumbing;
      case MaintenanceCategory.electrical:
        return Icons.electrical_services;
      case MaintenanceCategory.hvac:
        return Icons.ac_unit;
      case MaintenanceCategory.appliance:
        return Icons.kitchen;
      case MaintenanceCategory.structural:
        return Icons.foundation;
      case MaintenanceCategory.pestControl:
        return Icons.pest_control;
      case MaintenanceCategory.cleaning:
        return Icons.cleaning_services;
      case MaintenanceCategory.other:
        return Icons.build;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Category Icon box
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tenantColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(),
                      color: AppTheme.tenantColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Category & Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.categoryDisplay,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          _formatDate(request.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  StatusBadge(status: request.status),
                ],
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                request.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Description Preview
              Text(
                request.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer Row
              Row(
                children: [
                  // Location
                  Icon(
                    Icons.apartment_outlined,
                    size: 14,
                    color: AppTheme.tenantColor,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${request.spaceName} · Unit ${request.roomNumber}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Comments badge
                  if (request.commentCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.tenantColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.comment_outlined,
                            size: 12,
                            color: AppTheme.tenantColor,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${request.commentCount}',
                            style: TextStyle(
                              color: AppTheme.tenantColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Cancel pill
                  if (onCancel != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onCancel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.errorColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
