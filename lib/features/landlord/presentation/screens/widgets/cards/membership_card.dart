// membership_card.dart
import 'package:apartment_app/features/landlord/data/models/membership_model.dart';
import 'package:apartment_app/core/utils/currency_formatter.dart';
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
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _initials() {
    final first = (membership.userFirstName ?? '').trim();
    final last = (membership.userLastName ?? '').trim();

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (membership.userEmail != null && membership.userEmail!.trim().isNotEmpty) {
      return membership.userEmail!.trim()[0].toUpperCase();
    }
    return 'T';
  }

  @override
  Widget build(BuildContext context) {
    final isPending = membership.isPending;

    final displayName =
        membership.tenantFullName ?? membership.userEmail ?? 'Unknown Tenant';
    final email = membership.userEmail;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Name + Email + Status Badge
            Row(
              children: [
                // Avatar (initials)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.landlordColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.landlordColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name + Email + Joined
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name (primary)
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Email (secondary) - show only if we also have a name
                      if (membership.tenantFullName != null && email != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.getStatusColor(membership.status)
                        .withOpacity(0.1),
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

            // Room Info & Rent Details (for active members)
            if (membership.isActive) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.landlordColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.landlordColor.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Number
                    if (membership.roomNumber != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.door_front_door_outlined,
                            size: 16,
                            color: AppTheme.landlordColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Room ${membership.roomNumber}',
                            style: const TextStyle(
                              color: AppTheme.landlordColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                    // Rent Information
                    if (membership.monthlyRent != null ||
                        membership.rentStartDate != null ||
                        membership.paymentDueDay != null) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Monthly Rent
                      if (membership.monthlyRent != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_money,
                              size: 16,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${CurrencyFormatter.formatCents(membership.monthlyRent)}/month',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 6),

                      // Rent Start Date
                      if (membership.rentStartDate != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Starts: ${DateFormatter.formatDate(membership.rentStartDate)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 6),

                      // Payment Due Day
                      if (membership.paymentDueDay != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.event,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Due: ${membership.paymentDueDay}${_getDaySuffix(membership.paymentDueDay!)} of month',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ],

            // Actions (pending)
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

            // Actions (active)
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
