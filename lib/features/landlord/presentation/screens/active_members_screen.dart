import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/data/models/space_model.dart';
import 'package:apartment_app/features/landlord/presentation/providers/memberships_provider.dart';
import 'package:apartment_app/features/landlord/presentation/providers/rooms_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/membership_card.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/dialogs/room_selector_dialog.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/dialogs/approve_room_lease_dialog.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveMembersScreen extends ConsumerStatefulWidget {
  final Space space;

  const ActiveMembersScreen({
    super.key,
    required this.space,
  });

  @override
  ConsumerState<ActiveMembersScreen> createState() => _ActiveMembersScreenState();
}

class _ActiveMembersScreenState extends ConsumerState<ActiveMembersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membershipsProvider.notifier).loadActiveMembers(widget.space.id);
      ref.read(roomsProvider.notifier).loadRooms(widget.space.id);
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(membershipsProvider.notifier).loadActiveMembers(widget.space.id),
      ref.read(roomsProvider.notifier).loadRooms(widget.space.id),
    ]);
  }

  Future<void> _handleMove(
    String membershipId,
    String displayName,
    String? currentRoomNumber,
  ) async {
    final roomsState = ref.read(roomsProvider);
    final availableRooms = roomsState.rooms;

    if (availableRooms.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available rooms to move to.'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
      return;
    }

    final selectedRoomId = await showDialog<String>(
      context: context,
      builder: (context) => RoomSelectorDialog(
        availableRooms: availableRooms,
        title: 'Move $displayName to Room',
      ),
    );

    if (selectedRoomId == null || !mounted) return;

    try {
      await ref.read(membershipsProvider.notifier).moveMembership(
            membershipId,
            selectedRoomId,
            widget.space.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$displayName moved to new room',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to move member: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleRemove(String membershipId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove $displayName from this space?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_outlined, color: AppTheme.errorColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will permanently remove the member and end all their room leases.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(membershipsProvider.notifier).removeMembership(membershipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$displayName removed',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove member: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // 🆕 NEW: Approve room lease request
  Future<void> _handleApproveRoomLease(
    String membershipId,
    String leaseId,
    String roomNumber,
    String tenantName,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => ApproveRoomLeaseDialog(
        roomNumber: roomNumber,
        tenantName: tenantName,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await ref.read(membershipsProvider.notifier).approveRoomLease(
            membershipId: membershipId,
            leaseId: leaseId,
            monthlyRent: result['monthlyRent'] as int,
            rentStartDate: result['rentStartDate'] as DateTime,
            paymentDueDay: result['paymentDueDay'] as int,
            spaceId: widget.space.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Room $roomNumber lease approved for $tenantName',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve room lease: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // 🆕 NEW: Reject room lease request
  Future<void> _handleRejectRoomLease(
    String membershipId,
    String leaseId,
    String roomNumber,
    String tenantName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Room Request'),
        content: Text(
          'Are you sure you want to reject $tenantName\'s request for Room $roomNumber?',
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(membershipsProvider.notifier).rejectRoomLease(
            membershipId: membershipId,
            leaseId: leaseId,
            spaceId: widget.space.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Room $roomNumber request rejected',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject room lease: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // 🆕 NEW: End active room lease
  Future<void> _handleEndRoomLease(
    String membershipId,
    String leaseId,
    String roomNumber,
    String tenantName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Room Lease'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to end $tenantName\'s lease for Room $roomNumber?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.warningColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'The room will become available. The member will still have access to other rooms.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: const Text('End Lease'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(membershipsProvider.notifier).endRoomLease(
            membershipId: membershipId,
            leaseId: leaseId,
            spaceId: widget.space.id,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Room $roomNumber lease ended',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end room lease: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipsState = ref.watch(membershipsProvider);
    final activeMembers = membershipsState.activeMembers;
    final isLoading = membershipsState.isLoadingActive;

    return Scaffold(
      appBar: AppBar(
        title: Text('Active Members - ${widget.space.name}'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: isLoading && activeMembers.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : activeMembers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: activeMembers.length,
                    itemBuilder: (context, index) {
                      final member = activeMembers[index];

                      final displayName =
                          member.tenantFullName ?? member.userEmail ?? 'Tenant';

                      return MembershipCard(
                        membership: member,
                        onMove: () => _handleMove(
                          member.id,
                          displayName,
                          member.roomNumber,
                        ),
                        onRemove: () => _handleRemove(
                          member.id,
                          displayName,
                        ),
                        // 🆕 NEW: Room lease actions
                        onApproveRoomLease: (leaseId, roomNumber) =>
                            _handleApproveRoomLease(
                          member.id,
                          leaseId,
                          roomNumber,
                          displayName,
                        ),
                        onRejectRoomLease: (leaseId, roomNumber) =>
                            _handleRejectRoomLease(
                          member.id,
                          leaseId,
                          roomNumber,
                          displayName,
                        ),
                        onEndRoomLease: (leaseId, roomNumber) =>
                            _handleEndRoomLease(
                          member.id,
                          leaseId,
                          roomNumber,
                          displayName,
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.landlordColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 64,
                        color: AppTheme.landlordColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Active Members',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Approved tenants will appear here with their room assignments.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.landlordColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 20, color: AppTheme.landlordColor),
                              SizedBox(width: 8),
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.landlordColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            '1. Share join code with tenants\n2. Approve pending requests\n3. Assign rooms',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}