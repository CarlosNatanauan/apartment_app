import 'package:apartment_app/features/landlord/data/models/membership_model.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_memberships_provider.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_notices_provider.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_payments_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/tenant_announcements_section.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/tenant_payments_section.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TenantDashboard extends ConsumerStatefulWidget {
  const TenantDashboard({super.key});

  @override
  ConsumerState<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends ConsumerState<TenantDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    // Notices depend on memberships — ensure they are loaded first
    final membershipsState = ref.read(tenantMembershipsProvider);
    if (membershipsState.memberships.isEmpty) {
      await ref.read(tenantMembershipsProvider.notifier).loadMemberships();
    }

    ref.read(tenantNoticesProvider.notifier).loadAllNotices();
    ref.read(tenantPaymentsProvider.notifier).loadPayments();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(tenantMembershipsProvider.notifier).loadMemberships(),
      ref.read(tenantNoticesProvider.notifier).loadAllNotices(),
      ref.read(tenantPaymentsProvider.notifier).loadPayments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final membershipsState = ref.watch(tenantMembershipsProvider);
    final noticesState = ref.watch(tenantNoticesProvider);
    final paymentsState = ref.watch(tenantPaymentsProvider);

    final isLoading = (noticesState.isLoading && noticesState.notices.isEmpty) ||
        (paymentsState.isLoading && paymentsState.payments.isEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // My Spaces Overview
                  _MembershipOverviewCard(
                    activeMemberships: membershipsState.activeMemberships,
                    pendingMemberships: membershipsState.pendingMemberships,
                  ),

                  const SizedBox(height: 16),

                  // Announcements Section
                  const TenantAnnouncementsSection(),

                  const SizedBox(height: 16),

                  // Payments Section
                  const TenantPaymentsSection(),

                  const SizedBox(height: 16),
                ],
              ),
      ),
    );
  }
}

// My Spaces overview card — shows active and pending memberships at a glance
class _MembershipOverviewCard extends StatelessWidget {
  final List<Membership> activeMemberships;
  final List<Membership> pendingMemberships;

  const _MembershipOverviewCard({
    required this.activeMemberships,
    required this.pendingMemberships,
  });

  @override
  Widget build(BuildContext context) {
    final total = activeMemberships.length + pendingMemberships.length;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF059669), AppTheme.tenantColor],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.apartment, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'My Spaces',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (total > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$total',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(14),
            child: total == 0
                ? _buildEmptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...activeMemberships.map(
                        (m) => _buildMembershipRow(m, isActive: true),
                      ),
                      ...pendingMemberships.map(
                        (m) => _buildMembershipRow(m, isActive: false),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipRow(Membership membership, {required bool isActive}) {
    final color = isActive ? AppTheme.tenantColor : AppTheme.warningColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                isActive ? Icons.business_outlined : Icons.pending_outlined,
                size: 15,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                membership.spaceName ?? 'Space',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            if (isActive && membership.activeRoomCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.tenantColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${membership.activeRoomCount} Unit${membership.activeRoomCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.tenantColor,
                  ),
                ),
              ),
            if (!isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.textHint.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.textHint.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.tenantColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.apartment_outlined,
              size: 28,
              color: AppTheme.tenantColor,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'No active spaces',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'Join a space using your landlord\'s join code',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
