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
                  // Category Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.tenantColor.withOpacity(0.1),
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

              const SizedBox(height: 8),

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
                    Icons.location_on_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${request.spaceName} - Unit ${request.roomNumber}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Comments Count
                  if (request.commentCount > 0) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.comment_outlined,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${request.commentCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],

                  // Cancel Button
                  if (onCancel != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Cancel'),
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