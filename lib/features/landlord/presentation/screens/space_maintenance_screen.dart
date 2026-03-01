import 'package:apartment_app/features/landlord/presentation/providers/landlord_maintenance_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/landlord_maintenance_card.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceMaintenanceScreen extends ConsumerStatefulWidget {
  final String spaceId;
  final String spaceName;

  const SpaceMaintenanceScreen({
    super.key,
    required this.spaceId,
    required this.spaceName,
  });

  @override
  ConsumerState<SpaceMaintenanceScreen> createState() =>
      _SpaceMaintenanceScreenState();
}

class _SpaceMaintenanceScreenState extends ConsumerState<SpaceMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(landlordMaintenanceProvider.notifier)
          .loadSpaceRequests(widget.spaceId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref
        .read(landlordMaintenanceProvider.notifier)
        .loadSpaceRequests(widget.spaceId);
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
    final state = ref.watch(landlordMaintenanceProvider);
    final allRequests = state.requests;
    final pendingRequests = state.pendingRequests;
    final inProgressRequests = state.inProgressRequests;
    final completedRequests = state.completedRequests;
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Maintenance'),
            Text(
              widget.spaceName,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
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
                          allRequests.length, 'TOTAL', AppTheme.landlordColor),
                      const SizedBox(width: 6),
                      _buildStatChip(pendingRequests.length, 'PENDING',
                          AppTheme.warningColor),
                      const SizedBox(width: 6),
                      _buildStatChip(inProgressRequests.length, 'ACTIVE',
                          AppTheme.tenantColor),
                      const SizedBox(width: 6),
                      _buildStatChip(completedRequests.length, 'DONE',
                          AppTheme.successColor),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.landlordColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.landlordColor,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Pending'),
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
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
                _buildRequestsList(completedRequests, 'completed'),
              ],
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
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return LandlordMaintenanceCard(
            request: request,
            onTap: () => context.push(
              '/landlord/space/${widget.spaceId}/maintenance/${request.id}',
              extra: {'spaceName': widget.spaceName},
            ),
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
        message = 'All maintenance requests have been addressed.';
        icon = Icons.pending_actions;
        color = AppTheme.warningColor;
        break;
      case 'active':
        title = 'No Active Requests';
        message = 'No maintenance work is currently in progress.';
        icon = Icons.construction;
        color = AppTheme.tenantColor;
        break;
      case 'completed':
        title = 'No Completed Requests';
        message = 'Completed maintenance requests will appear here.';
        icon = Icons.check_circle_outline;
        color = AppTheme.successColor;
        break;
      default:
        title = 'No Maintenance Requests';
        message = 'Tenants haven\'t reported any issues yet.';
        icon = Icons.build_circle_outlined;
        color = AppTheme.landlordColor;
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
