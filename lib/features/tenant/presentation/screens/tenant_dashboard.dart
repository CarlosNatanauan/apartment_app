import 'package:apartment_app/features/tenant/presentation/provider/tenant_notices_provider.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_payments_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/tenant_announcements_section.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/tenant_payments_section.dart';
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
    // Load dashboard data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  void _loadDashboardData() {
    // Load announcements from all spaces
    ref.read(tenantNoticesProvider.notifier).loadAllNotices();
    
    // Load current month's payments
    ref.read(tenantPaymentsProvider.notifier).loadPayments();
  }

  Future<void> _handleRefresh() async {
    await Future.wait([
      ref.read(tenantNoticesProvider.notifier).loadAllNotices(),
      ref.read(tenantPaymentsProvider.notifier).loadPayments(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
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
                children: const [
                  // Announcements Section
                  TenantAnnouncementsSection(),

                  SizedBox(height: 16),

                  // Payments Section
                  TenantPaymentsSection(),
                ],
              ),
      ),
    );
  }
}