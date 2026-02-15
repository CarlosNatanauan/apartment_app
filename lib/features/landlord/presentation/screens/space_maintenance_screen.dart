import 'package:apartment_app/core/api/api_response.dart';
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

class _SpaceMaintenanceScreenState
    extends ConsumerState<SpaceMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load requests on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(landlordMaintenanceProvider.notifier).loadSpaceRequests(widget.spaceId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await ref.read(landlordMaintenanceProvider.notifier).loadSpaceRequests(widget.spaceId);
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.landlordColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.landlordColor,
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${allRequests.length})'),
            Tab(text: 'Pending (${pendingRequests.length})'),
            Tab(text: 'Active (${inProgressRequests.length})'),
            Tab(text: 'Completed (${completedRequests.length})'),
          ],
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

    switch (type) {
      case 'pending':
        title = 'No Pending Requests';
        message = 'All maintenance requests have been addressed.';
        icon = Icons.pending_actions;
        break;
      case 'active':
        title = 'No Active Requests';
        message = 'No maintenance work is currently in progress.';
        icon = Icons.construction;
        break;
      case 'completed':
        title = 'No Completed Requests';
        message = 'Completed maintenance requests will appear here.';
        icon = Icons.check_circle_outline;
        break;
      default:
        title = 'No Maintenance Requests';
        message = 'Tenants haven\'t reported any issues yet.';
        icon = Icons.build_circle_outlined;
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
                        color: AppTheme.landlordColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 64,
                        color: AppTheme.landlordColor,
                      ),
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