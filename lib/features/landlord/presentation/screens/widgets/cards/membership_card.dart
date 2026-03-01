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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), AppTheme.landlordColor],
              ),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Avatar (frosted circle with initials)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 14,
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
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (membership.tenantFullName != null &&
                          email != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (membership.createdAt != null) ...[
                        const SizedBox(height: 1),
                        Text(
                          'Joined ${_formatDate(membership.createdAt!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Status badge (frosted pill)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    membership.status,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Card body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Room Leases Section (for ACTIVE memberships)
                if (isActive && membership.roomLeases.isNotEmpty) ...[
                  Row(
                    children: [
                      // Active Rooms Badge
                      if (membership.hasActiveLeases)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.meeting_room,
                                size: 14,
                                color: AppTheme.successColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${membership.activeRoomCount} Active',
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 12,
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.pending_outlined,
                                size: 14,
                                color: AppTheme.warningColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${membership.pendingRoomCount} Pending',
                                style: const TextStyle(
                                  color: AppTheme.warningColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Expand/Collapse toggle pill
                      InkWell(
                        onTap: () =>
                            setState(() => _isExpanded = !_isExpanded),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.landlordColor
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.landlordColor
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded ? 'Hide' : 'Details',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.landlordColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                _isExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 16,
                                color: AppTheme.landlordColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Expandable Room Leases List
                if (isActive &&
                    _isExpanded &&
                    membership.roomLeases.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.landlordColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            AppTheme.landlordColor.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (membership.activeLeases.isNotEmpty) ...[
                          _buildSectionHeader(
                              'Active Units', Icons.check_circle),
                          const SizedBox(height: 8),
                          ...membership.activeLeases.map((lease) =>
                              _buildLeaseItem(lease, context, 'active')),
                        ],
                        if (membership.pendingLeases.isNotEmpty) ...[
                          if (membership.activeLeases.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                          ],
                          _buildSectionHeader(
                              'Pending Requests', Icons.pending_outlined),
                          const SizedBox(height: 8),
                          ...membership.pendingLeases.map((lease) =>
                              _buildLeaseItem(lease, context, 'pending')),
                        ],
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

                // Backward compat: single room display (collapsed)
                if (isActive &&
                    !_isExpanded &&
                    membership.roomNumber != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.landlordColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            AppTheme.landlordColor.withValues(alpha: 0.12),
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
                              const Icon(Icons.attach_money,
                                  size: 16,
                                  color: AppTheme.textSecondary),
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
                          if (membership.paymentDueDay != null)
                            Row(
                              children: [
                                const Icon(Icons.event,
                                    size: 14,
                                    color: AppTheme.textSecondary),
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
                if (isPending &&
                    (widget.onApprove != null ||
                        widget.onReject != null)) ...[
                  const SizedBox(height: 14),
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
                              side: const BorderSide(
                                  color: AppTheme.errorColor),
                            ),
                          ),
                        ),
                      if (widget.onReject != null &&
                          widget.onApprove != null)
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
                if (isActive &&
                    (widget.onMove != null ||
                        widget.onRemove != null)) ...[
                  const SizedBox(height: 14),
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
                      if (widget.onMove != null &&
                          widget.onRemove != null)
                        const SizedBox(width: 12),
                      if (widget.onRemove != null)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onRemove,
                            icon: const Icon(Icons.person_remove, size: 18),
                            label: const Text('Remove'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(
                                  color: AppTheme.errorColor),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppTheme.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: AppTheme.textSecondary),
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildLeaseItem(
      RoomLease lease, BuildContext context, String type) {
    final statusColor = _getLeaseStatusColor(lease.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Number + Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(
                    Icons.door_front_door_outlined,
                    size: 14,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Room ${lease.roomNumber ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
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
                  const Icon(Icons.attach_money,
                      size: 14, color: AppTheme.textSecondary),
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
                  const Icon(Icons.calendar_today,
                      size: 12, color: AppTheme.textSecondary),
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
                (widget.onApproveRoomLease != null ||
                    widget.onRejectRoomLease != null)) ...[
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
                        label: const Text('Reject',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                          side:
                              const BorderSide(color: AppTheme.errorColor),
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  if (widget.onRejectRoomLease != null &&
                      widget.onApproveRoomLease != null)
                    const SizedBox(width: 8),
                  if (widget.onApproveRoomLease != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onApproveRoomLease!(
                          lease.leaseId,
                          lease.roomNumber ?? 'N/A',
                        ),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve',
                            style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
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
                  label: const Text('End Lease',
                      style: TextStyle(fontSize: 12)),
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
