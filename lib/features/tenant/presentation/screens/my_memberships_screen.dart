import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_memberships_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/cards/tenant_membership_card.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyMembershipsScreen extends ConsumerStatefulWidget {
  const MyMembershipsScreen({super.key});

  @override
  ConsumerState<MyMembershipsScreen> createState() => _MyMembershipsScreenState();
}

class _MyMembershipsScreenState extends ConsumerState<MyMembershipsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tenantMembershipsProvider.notifier).loadMemberships();
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(tenantMembershipsProvider.notifier).loadMemberships();
  }

  Future<void> _handleLeave(String membershipId, String spaceName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Space'),
        content: Text(
          'Are you sure you want to leave "$spaceName"?\n\nThis action cannot be undone.',
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
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(tenantMembershipsProvider.notifier).leaveSpace(membershipId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Left "$spaceName" successfully',
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
            content: Text('Failed to leave space: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantMembershipsProvider);
    final memberships = state.memberships;
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Spaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: isLoading && memberships.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : memberships.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: memberships.length,
                    itemBuilder: (context, index) {
                      final membership = memberships[index];
                      return TenantMembershipCard(
                        membership: membership,
                        onLeave: membership.isActive
                            ? () => _handleLeave(
                                  membership.id,
                                  membership.spaceName ?? 'Space',
                                )
                            : null,
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tenant/join-space'),
        icon: const Icon(Icons.add),
        label: const Text('Join Space'),
        backgroundColor: AppTheme.tenantColor,
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
                        color: AppTheme.tenantColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apartment,
                        size: 64,
                        color: AppTheme.tenantColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Spaces Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join a space using a code from your landlord to get started.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/tenant/join-space'),
                      icon: const Icon(Icons.add),
                      label: const Text('Join Your First Space'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.tenantColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
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