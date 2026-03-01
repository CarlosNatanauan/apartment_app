// pending_requests_screen.dart
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/data/models/space_model.dart';
import 'package:apartment_app/features/landlord/presentation/providers/memberships_provider.dart';
import 'package:apartment_app/features/landlord/presentation/providers/rooms_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/approve_membership_dialog.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/membership_card.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PendingRequestsScreen extends ConsumerStatefulWidget {
  final Space space;

  const PendingRequestsScreen({
    super.key,
    required this.space,
  });

  @override
  ConsumerState<PendingRequestsScreen> createState() =>
      _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends ConsumerState<PendingRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(membershipsProvider.notifier)
          .loadPendingRequests(widget.space.id);
      ref.read(roomsProvider.notifier).loadRooms(widget.space.id);
    });
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(membershipsProvider.notifier).loadPendingRequests(widget.space.id),
      ref.read(roomsProvider.notifier).loadRooms(widget.space.id),
    ]);
  }

  // ✅ UPDATED: use displayName (name preferred, fallback email)
  Future<void> _handleApprove(
    String membershipId,
    String displayName,
    String tenantEmailForDialog,
  ) async {
    final roomsState = ref.read(roomsProvider);

    final availableRooms =
        roomsState.rooms.where((room) => !room.isOccupied).toList();

    if (availableRooms.isEmpty) {
      if (mounted) {
        final totalRooms = roomsState.rooms.length;
        final occupiedRooms = roomsState.rooms.where((r) => r.isOccupied).length;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              totalRooms == 0
                  ? 'No units created. Please create units first.'
                  : 'All $totalRooms units are occupied ($occupiedRooms/$totalRooms). Cannot approve new member.',
            ),
            backgroundColor: AppTheme.warningColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final approvalData = await showDialog<ApprovalData>(
      context: context,
      builder: (context) => ApproveMembershipDialog(
        availableRooms: availableRooms,
        tenantEmail: tenantEmailForDialog,
      ),
    );

    if (approvalData == null || !mounted) return;

    try {
      await ref.read(membershipsProvider.notifier).approveMembership(
            membershipId: membershipId,
            roomId: approvalData.roomId,
            spaceId: widget.space.id,
            monthlyRent: approvalData.monthlyRent,
            rentStartDate: approvalData.rentStartDate,
            paymentDueDay: approvalData.paymentDueDay,
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
                    '$displayName approved and assigned to unit',
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
            content: Text('Failed to approve: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  // ✅ UPDATED: use displayName
  Future<void> _handleReject(String membershipId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content:
            Text('Are you sure you want to reject the request from $displayName?'),
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(membershipsProvider.notifier).rejectMembership(membershipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$displayName rejected',
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
            content: Text('Failed to reject: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membershipsState = ref.watch(membershipsProvider);
    final pendingRequests = membershipsState.pendingRequests;
    final isLoading = membershipsState.isLoadingPending;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pending Requests - ${widget.space.name}'),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: isLoading && pendingRequests.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : pendingRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    itemCount: pendingRequests.length,
                    itemBuilder: (context, index) {
                      final request = pendingRequests[index];

                      final displayName =
                          request.tenantFullName ?? request.userEmail ?? 'Tenant';
                      final tenantEmailForDialog =
                          request.userEmail ?? displayName;

                      return MembershipCard(
                        membership: request,
                        onApprove: () => _handleApprove(
                          request.id,
                          displayName,
                          tenantEmailForDialog,
                        ),
                        onReject: () => _handleReject(
                          request.id,
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
                        color: AppTheme.landlordColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AppTheme.landlordColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Pending Requests',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tenants who join this space will appear here for approval.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.landlordColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 20, color: AppTheme.landlordColor),
                              SizedBox(width: 8),
                              Text(
                                'Share Join Code',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.landlordColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Share the join code "${widget.space.joinCode}" with tenants so they can request to join.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
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
