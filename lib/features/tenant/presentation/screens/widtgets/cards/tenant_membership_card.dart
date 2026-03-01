import 'package:apartment_app/features/landlord/data/models/membership_model.dart';
import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_memberships_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/request_room_dialog.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantMembershipCard extends ConsumerStatefulWidget {
  final Membership membership;
  final VoidCallback? onTap;
  final VoidCallback? onLeave;

  const TenantMembershipCard({
    super.key,
    required this.membership,
    this.onTap,
    this.onLeave,
  });

  @override
  ConsumerState<TenantMembershipCard> createState() => _TenantMembershipCardState();
}

class _TenantMembershipCardState extends ConsumerState<TenantMembershipCard> {
  bool _isExpanded = false;
  bool _isRequestingRoom = false;
  final Set<String> _leavingLeases = {}; // Track which leases are being left

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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _handleRequestAnotherRoom() async {
    if (widget.membership.spaceId == null) return;

    // Get current room IDs (from all leases, not just active)
    final currentRoomIds = widget.membership.roomLeases
        .where((lease) => lease.roomId != null)
        .map((lease) => lease.roomId!)
        .toList();

    final selectedRoomId = await showDialog<String>(
      context: context,
      builder: (context) => RequestRoomDialog(
        spaceId: widget.membership.spaceId!,
        spaceName: widget.membership.spaceName ?? 'Space',
        currentRoomIds: currentRoomIds,
      ),
    );

    if (selectedRoomId == null || !mounted) return;

    setState(() => _isRequestingRoom = true);

    try {
      await ref.read(tenantMembershipsProvider.notifier).requestRoomLease(
            membershipId: widget.membership.id,
            roomId: selectedRoomId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Unit request submitted successfully'),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request unit: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingRoom = false);
      }
    }
  }

  // 🆕 NEW: Leave a single room
  Future<void> _handleLeaveRoom(RoomLease lease) async {
    final roomNumber = lease.roomNumber ?? 'Unknown';
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Unit'),
        content: Text(
          'Are you sure you want to leave Unit $roomNumber?\n\n'
          '${widget.membership.activeRoomCount > 1
              ? 'You will still have access to your other units in this space.'
              : 'This is your only unit. Leaving it will remove you from the space entirely.'}'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Leave Unit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _leavingLeases.add(lease.leaseId));

    try {
      await ref.read(tenantMembershipsProvider.notifier).leaveRoomLease(
            membershipId: widget.membership.id,
            leaseId: lease.leaseId,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Left Unit $roomNumber successfully'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave unit: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _leavingLeases.remove(lease.leaseId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membership = widget.membership;
    final isPending = membership.isPending;
    final isActive = membership.isActive;
    
    final landlordName = membership.landlordFullName;
    final landlordEmail = membership.landlordEmail;
    final hasLandlord = (landlordName != null && landlordName.trim().isNotEmpty) ||
        (landlordEmail != null && landlordEmail.trim().isNotEmpty);

    // Header gradient varies by status
    final List<Color> headerGradient = membership.isPending
        ? [const Color(0xFFD97706), AppTheme.warningColor]
        : membership.isRejected
            ? [const Color(0xFFDC2626), AppTheme.errorColor]
            : [const Color(0xFF059669), AppTheme.tenantColor];

    return Card(
      child: Column(
        children: [
          // ── Gradient header ──────────────────────────────────────
          InkWell(
            onTap: widget.onTap,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: headerGradient,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apartment, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          membership.spaceName ?? 'Space',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (membership.createdAt != null)
                          Text(
                            'Requested ${_formatDate(membership.createdAt!)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          ),

          // ── Body ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pending: waiting message
                if (isPending) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.warningColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.pending_outlined,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Waiting for landlord approval',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (hasLandlord) ...[
                                const SizedBox(height: 4),
                                if (landlordName != null)
                                  Text(
                                    landlordName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.warningColor.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (landlordEmail != null)
                                  Text(
                                    landlordEmail,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.warningColor.withValues(alpha: 0.75),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Active membership body
                if (isActive) ...[
                  // Landlord info
                  if (hasLandlord) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.tenantColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              size: 16,
                              color: AppTheme.tenantColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (landlordName != null)
                                  Text(
                                    landlordName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                if (landlordEmail != null)
                                  Text(
                                    landlordEmail,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Room badges + expand/collapse toggle
                  if (membership.hasActiveLeases || membership.hasPendingLeases) ...[
                    Row(
                      children: [
                        if (membership.hasActiveLeases)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.tenantColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.meeting_room, size: 14, color: AppTheme.tenantColor),
                                const SizedBox(width: 5),
                                Text(
                                  '${membership.activeRoomCount} Unit${membership.activeRoomCount > 1 ? 's' : ''}',
                                  style: const TextStyle(
                                    color: AppTheme.tenantColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (membership.hasPendingLeases) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pending_outlined, size: 14, color: AppTheme.warningColor),
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
                        GestureDetector(
                          onTap: () => setState(() => _isExpanded = !_isExpanded),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.tenantColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _isExpanded ? 'Hide' : 'Details',
                                  style: const TextStyle(
                                    color: AppTheme.tenantColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                  color: AppTheme.tenantColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Expanded lease details
                  if (_isExpanded && membership.roomLeases.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.tenantColor.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.tenantColor.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (membership.activeLeases.isNotEmpty) ...[
                            _buildSectionHeader('Active Units', Icons.check_circle),
                            const SizedBox(height: 8),
                            ...membership.activeLeases.map((l) => _buildLeaseItem(l, true)),
                          ],
                          if (membership.pendingLeases.isNotEmpty) ...[
                            if (membership.activeLeases.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                            ],
                            _buildSectionHeader('Pending Requests', Icons.pending_outlined),
                            const SizedBox(height: 8),
                            ...membership.pendingLeases.map((l) => _buildLeaseItem(l, false)),
                          ],
                          if (membership.rejectedLeases.isNotEmpty) ...[
                            if (membership.activeLeases.isNotEmpty || membership.pendingLeases.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                            ],
                            _buildSectionHeader('Rejected', Icons.cancel_outlined),
                            const SizedBox(height: 8),
                            ...membership.rejectedLeases.map((l) => _buildLeaseItem(l, false)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isRequestingRoom ? null : _handleRequestAnotherRoom,
                          icon: _isRequestingRoom
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_home, size: 16),
                          label: const Text('Request Unit'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.tenantColor,
                            side: const BorderSide(color: AppTheme.tenantColor),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (widget.onLeave != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onLeave,
                            icon: const Icon(Icons.exit_to_app, size: 16),
                            label: const Text('Leave'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                              side: const BorderSide(color: AppTheme.errorColor),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Member since date
                  if (membership.approvedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Member since ${_formatDate(membership.approvedAt!)}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textHint),
                    ),
                  ],
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

  Widget _buildLeaseItem(RoomLease lease, bool showRentInfo) {
    final statusColor = _getLeaseStatusColor(lease.status);
    final isLeaving = _leavingLeases.contains(lease.leaseId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unit number + status badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.door_front_door_outlined, size: 14, color: statusColor),
                ),
                const SizedBox(width: 8),
                Text(
                  'Unit ${lease.roomNumber ?? 'N/A'}',
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
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lease.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            // Rent info (active leases)
            if (showRentInfo && lease.hasRentInfo) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    CurrencyFormatter.formatCents(lease.monthlyRent!),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.tenantColor,
                    ),
                  ),
                  const Text(
                    '/month',
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const Spacer(),
                  const Icon(Icons.calendar_today, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Due ${lease.paymentDueDay}${_getDaySuffix(lease.paymentDueDay!)}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isLeaving ? null : () => _handleLeaveRoom(lease),
                  icon: isLeaving
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.exit_to_app, size: 13),
                  label: const Text('Leave Unit', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],

            // Requested date (pending/rejected)
            if (!showRentInfo && lease.requestedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Requested ${_formatDate(lease.requestedAt!)}',
                style: const TextStyle(fontSize: 10, color: AppTheme.textHint),
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