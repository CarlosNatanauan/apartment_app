import 'package:apartment_app/features/landlord/data/models/membership_model.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MembershipCard extends StatelessWidget {
  final Membership membership;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;

  const MembershipCard({
    super.key,
    required this.membership,
    this.onApprove,
    this.onReject,
    this.onMove,
    this.onRemove,
  });

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPending = membership.isPending;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Email + Status Badge
            Row(
              children: [
                // User Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.landlordColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 20,
                    color: AppTheme.landlordColor,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        membership.userEmail ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      if (membership.createdAt != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Joined ${_formatDate(membership.createdAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(membership.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    membership.status,
                    style: TextStyle(
                      color: AppTheme.getStatusColor(membership.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            // Room Info (for active members)
            if (membership.isActive && membership.roomNumber != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.door_front_door_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Room ${membership.roomNumber}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            
            // Actions (different for pending vs active)
            if (isPending && (onApprove != null || onReject != null)) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                  if (onReject != null && onApprove != null)
                    const SizedBox(width: 12),
                  if (onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            
            // Actions (for active members)
            if (membership.isActive && (onMove != null || onRemove != null)) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (onMove != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMove,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Move'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.landlordColor,
                        ),
                      ),
                    ),
                  if (onMove != null && onRemove != null)
                    const SizedBox(width: 12),
                  if (onRemove != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onRemove,
                        icon: const Icon(Icons.person_remove, size: 18),
                        label: const Text('Remove'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}