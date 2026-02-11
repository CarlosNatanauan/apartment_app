import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/data/models/space_model.dart';
import 'package:apartment_app/features/landlord/presentation/providers/memberships_provider.dart';
import 'package:apartment_app/features/landlord/presentation/providers/rooms_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/membership_card.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/dialogs/room_selector_dialog.dart';
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
    // Load active members and rooms when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(membershipsProvider.notifier).loadActiveMembers(widget.space.id);
      ref.read(roomsProvider.notifier).loadRooms(widget.space.id);
    });
  }

  // Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(membershipsProvider.notifier).loadActiveMembers(widget.space.id),
      ref.read(roomsProvider.notifier).loadRooms(widget.space.id),
    ]);
  }

  // Move member to different room
  Future<void> _handleMove(String membershipId, String userEmail, String? currentRoomNumber) async {
    // Get available rooms (not occupied)
    final roomsState = ref.read(roomsProvider);
    final availableRooms = roomsState.rooms; // TODO: Filter out occupied rooms (except current)
    
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

    // Show room selector dialog
    final selectedRoomId = await showDialog<String>(
      context: context,
      builder: (context) => RoomSelectorDialog(
        availableRooms: availableRooms,
        title: 'Move $userEmail to Room',
      ),
    );

    if (selectedRoomId == null || !mounted) return;

    // Move membership to selected room
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
                // ✅ Wrap Text in Expanded to prevent overflow
                Expanded(
                  child: Text(
                    '$userEmail moved to new room',
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

  // Remove member (kick out)
  Future<void> _handleRemove(String membershipId, String userEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove $userEmail from this space?'),
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
                      'This will permanently remove the member and free up their room.',
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
                // ✅ Wrap Text in Expanded
                Expanded(
                  child: Text(
                    '$userEmail removed',
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
                      return MembershipCard(
                        membership: member,
                        onMove: () => _handleMove(
                          member.id,
                          member.userEmail ?? 'User',
                          member.roomNumber,
                        ),
                        onRemove: () => _handleRemove(
                          member.id,
                          member.userEmail ?? 'User',
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
                      child: Column(
                        children: [
                          const Row(
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
                          const SizedBox(height: 8),
                          const Text(
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