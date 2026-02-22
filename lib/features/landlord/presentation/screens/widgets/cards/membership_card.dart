import 'package:apartment_app/features/landlord/data/models/membership_model.dart';
import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MembershipCard extends StatefulWidget {
  final Membership membership;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onMove;
  final VoidCallback? onRemove;
  // 🆕 NEW: Room lease actions
  final Function(String leaseId, String roomNumber)? onApproveRoomLease;
  final Function(String leaseId, String roomNumber)? onRejectRoomLease;
  final Function(String leaseId, String roomNumber)? onEndRoomLease;

  const MembershipCard({
    super.key,
    required this.membership,
    this.onApprove,
    this.onReject,
    this.onMove,
    this.onRemove,
    this.onApproveRoomLease,
    this.onRejectRoomLease,
    this.onEndRoomLease,
  });

  @override
  State<MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<MembershipCard> {
  bool _isExpanded = false;

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
    final first = (widget.membership.userFirstName ?? '').trim();
    final last = (widget.membership.userLastName ?? '').trim();

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (widget.membership.userEmail != null &&
        widget.membership.userEmail!.trim().isNotEmpty) {
      return widget.membership.userEmail!.trim()[0].toUpperCase();
    }
    return 'T';
  }

  @override
  Widget build(BuildContext context) {
    final membership = widget.membership;
    final isPending = membership.isPending;
    final isActive = membership.isActive;

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
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

            // 🆕 NEW: Room Leases Section (for ACTIVE memberships)
            if (isActive && membership.roomLeases.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Active Rooms Badge
                  if (membership.hasActiveLeases)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.meeting_room,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${membership.activeRoomCount} Active',
                            style: const TextStyle(
                              color: AppTheme.successColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Pending Rooms Badge
                  if (membership.hasPendingLeases) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.warningColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pending_outlined,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${membership.pendingRoomCount} Pending',
                            style: const TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Expand/Collapse Button
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppTheme.landlordColor,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],

            // Expandable Room Leases List
            if (isActive && _isExpanded && membership.roomLeases.isNotEmpty) ...[
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
                    // Active Leases
                    if (membership.activeLeases.isNotEmpty) ...[
                      _buildSectionHeader('Active Rooms', Icons.check_circle),
                      const SizedBox(height: 8),
                      ...membership.activeLeases.map((lease) =>
                          _buildLeaseItem(lease, context, 'active')),
                    ],

                    // Pending Leases
                    if (membership.pendingLeases.isNotEmpty) ...[
                      if (membership.activeLeases.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                      ],
                      _buildSectionHeader('Pending Requests', Icons.pending_outlined),
                      const SizedBox(height: 8),
                      ...membership.pendingLeases.map((lease) =>
                          _buildLeaseItem(lease, context, 'pending')),
                    ],

                    // Rejected/Ended Leases (collapsed by default)
                    if (membership.rejectedLeases.isNotEmpty ||
                        membership.endedLeases.isNotEmpty) ...[
                      if (membership.activeLeases.isNotEmpty ||
                          membership.pendingLeases.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                      ],
                      _buildSectionHeader('History', Icons.history),
                      const SizedBox(height: 8),
                      ...membership.rejectedLeases.map((lease) =>
                          _buildLeaseItem(lease, context, 'rejected')),
                      ...membership.endedLeases.map((lease) =>
                          _buildLeaseItem(lease, context, 'ended')),
                    ],
                  ],
                ),
              ),
            ],

            // Old Single Room Display (for backward compatibility, only if not expanded)
            if (isActive && !_isExpanded && membership.roomNumber != null) ...[
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
                    if (membership.hasRentInfo) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${CurrencyFormatter.formatCents(membership.monthlyRent!)}/month',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
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
                              'Starts: ${DateFormatter.formatDate(membership.rentStartDate!)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
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

            // Actions (pending membership)
            if (isPending && (widget.onApprove != null || widget.onReject != null)) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.onReject != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onReject,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                        ),
                      ),
                    ),
                  if (widget.onReject != null && widget.onApprove != null)
                    const SizedBox(width: 12),
                  if (widget.onApprove != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: widget.onApprove,
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

            // Actions (active membership)
            if (isActive && (widget.onMove != null || widget.onRemove != null)) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (widget.onMove != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onMove,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Move'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.landlordColor,
                        ),
                      ),
                    ),
                  if (widget.onMove != null && widget.onRemove != null)
                    const SizedBox(width: 12),
                  if (widget.onRemove != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onRemove,
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaseItem(RoomLease lease, BuildContext context, String type) {
    final statusColor = _getLeaseStatusColor(lease.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Number + Status
            Row(
              children: [
                Icon(
                  Icons.door_front_door_outlined,
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Room ${lease.roomNumber ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: statusColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    lease.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            // Rent Info (for active leases)
            if (type == 'active' && lease.hasRentInfo) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    CurrencyFormatter.formatCents(lease.monthlyRent!),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/month',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${lease.paymentDueDay}${_getDaySuffix(lease.paymentDueDay!)} of month',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            // Requested date (for pending/rejected/ended)
            if (type != 'active' && lease.requestedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Requested ${_formatDate(lease.requestedAt!)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.textHint,
                ),
              ),
            ],

            // Actions (for pending leases)
            if (type == 'pending' &&
                (widget.onApproveRoomLease != null || widget.onRejectRoomLease != null)) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  if (widget.onRejectRoomLease != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onRejectRoomLease!(
                          lease.leaseId,
                          lease.roomNumber ?? 'N/A',
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side: const BorderSide(color: AppTheme.errorColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (widget.onRejectRoomLease != null && widget.onApproveRoomLease != null)
                    const SizedBox(width: 8),
                  if (widget.onApproveRoomLease != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onApproveRoomLease!(
                          lease.leaseId,
                          lease.roomNumber ?? 'N/A',
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Actions (for active leases)
            if (type == 'active' && widget.onEndRoomLease != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => widget.onEndRoomLease!(
                    lease.leaseId,
                    lease.roomNumber ?? 'N/A',
                  ),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('End Lease', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                    side: const BorderSide(color: AppTheme.warningColor),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getLeaseStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return AppTheme.successColor;
      case 'PENDING':
        return AppTheme.warningColor;
      case 'REJECTED':
        return AppTheme.errorColor;
      case 'ENDED':
        return AppTheme.textHint;
      default:
        return AppTheme.textSecondary;
    }
  }
}