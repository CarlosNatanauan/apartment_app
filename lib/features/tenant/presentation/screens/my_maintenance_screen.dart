import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/tenant/presentation/provider/maintenance_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/widtgets/cards/maintenance_request_card.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyMaintenanceScreen extends ConsumerStatefulWidget {
  const MyMaintenanceScreen({super.key});

  @override
  ConsumerState<MyMaintenanceScreen> createState() =>
      _MyMaintenanceScreenState();
}

class _MyMaintenanceScreenState extends ConsumerState<MyMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(maintenanceProvider.notifier).loadRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(maintenanceProvider.notifier).loadRequests();
  }

  Future<void> _handleCancel(String requestId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: Text(
          'Are you sure you want to cancel "$title"?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(maintenanceProvider.notifier).cancelRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Request cancelled successfully',
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
            content: Text('Failed to cancel request: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildStatChip(int count, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceProvider);
    final allRequests = state.requests;
    final pendingRequests = state.pendingRequests;
    final inProgressRequests = state.inProgressRequests;
    final completedRequests = state.completedRequests;
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(102),
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                // Stats chips row
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      _buildStatChip(
                          allRequests.length, 'TOTAL', AppTheme.tenantColor),
                      const SizedBox(width: 6),
                      _buildStatChip(pendingRequests.length, 'PENDING',
                          AppTheme.warningColor),
                      const SizedBox(width: 6),
                      _buildStatChip(inProgressRequests.length, 'ACTIVE',
                          AppTheme.primaryColor),
                      const SizedBox(width: 6),
                      _buildStatChip(completedRequests.length, 'DONE',
                          AppTheme.successColor),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // TabBar
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.tenantColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.tenantColor,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Active'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading && allRequests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsList(allRequests, 'all'),
                _buildRequestsList(pendingRequests, 'pending'),
                _buildRequestsList(inProgressRequests, 'active'),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tenant/maintenance/create'),
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
        backgroundColor: AppTheme.tenantColor,
      ),
    );
  }

  Widget _buildRequestsList(List requests, String type) {
    if (requests.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return MaintenanceRequestCard(
            request: request,
            onTap: () =>
                context.push('/tenant/maintenance/details/${request.id}'),
            onCancel: request.canCancel
                ? () => _handleCancel(request.id, request.title)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String message;
    IconData icon;
    Color color;

    switch (type) {
      case 'pending':
        title = 'No Pending Requests';
        message = 'You have no maintenance requests awaiting response.';
        icon = Icons.pending_actions;
        color = AppTheme.warningColor;
        break;
      case 'active':
        title = 'No Active Requests';
        message = 'You have no maintenance requests in progress.';
        icon = Icons.construction;
        color = AppTheme.primaryColor;
        break;
      default:
        title = 'No Maintenance Requests';
        message =
            'Create a request to report any issues with your apartment.';
        icon = Icons.build_circle_outlined;
        color = AppTheme.tenantColor;
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 300,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 64, color: color),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (type == 'all') ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.push('/tenant/maintenance/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create First Request'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.tenantColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
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
