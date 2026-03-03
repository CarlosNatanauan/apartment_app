import 'package:apartment_app/features/landlord/presentation/providers/landlord_maintenance_provider.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/landlord_maintenance_card.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AllSpacesMaintenanceScreen extends ConsumerStatefulWidget {
  const AllSpacesMaintenanceScreen({super.key});

  @override
  ConsumerState<AllSpacesMaintenanceScreen> createState() =>
      _AllSpacesMaintenanceScreenState();
}

class _AllSpacesMaintenanceScreenState
    extends ConsumerState<AllSpacesMaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSpaceId; // null = "All Spaces"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spacesProvider.notifier).loadSpaces();
      ref.read(landlordMaintenanceProvider.notifier).loadAllSpacesRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_selectedSpaceId == null) {
      await ref
          .read(landlordMaintenanceProvider.notifier)
          .loadAllSpacesRequests();
    } else {
      await ref
          .read(landlordMaintenanceProvider.notifier)
          .loadSpaceRequests(_selectedSpaceId!);
    }
  }

  void _handleSpaceFilterChange(String? spaceId) {
    setState(() => _selectedSpaceId = spaceId);
    if (spaceId == null) {
      ref.read(landlordMaintenanceProvider.notifier).loadAllSpacesRequests();
    } else {
      ref.read(landlordMaintenanceProvider.notifier).loadSpaceRequests(spaceId);
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
    final maintenanceState = ref.watch(landlordMaintenanceProvider);
    final spacesState = ref.watch(spacesProvider);

    final allRequests = maintenanceState.requests;
    final pendingRequests = maintenanceState.pendingRequests;
    final inProgressRequests = maintenanceState.inProgressRequests;
    final completedRequests = maintenanceState.completedRequests;
    final isLoading = maintenanceState.isLoading;
    final spaces = spacesState.spaces;

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
          preferredSize: const Size.fromHeight(152),
          child: Material(
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Space filter selector
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    children: [
                      // Icon box
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.landlordColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.business_outlined,
                          color: AppTheme.landlordColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String?>(
                          value: _selectedSpaceId,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(
                            Icons.expand_more,
                            color: AppTheme.landlordColor,
                            size: 20,
                          ),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Spaces'),
                            ),
                            ...spaces.map(
                              (space) => DropdownMenuItem<String?>(
                                value: space.id,
                                child: Text(
                                  space.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                          onChanged: _handleSpaceFilterChange,
                        ),
                      ),
                    ],
                  ),
                ),

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
                    Tab(text: 'In Progress'),
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
                _buildRequestsList(inProgressRequests, 'inprogress'),
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
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return LandlordMaintenanceCard(
            request: request,
            onTap: () {
              context.push(
                '/landlord/maintenance/${request.spaceId}/${request.id}',
                extra: {'spaceName': request.spaceName},
              );
            },
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
        message = 'No maintenance requests awaiting your response.';
        icon = Icons.pending_actions;
        color = AppTheme.warningColor;
        break;
      case 'inprogress':
        title = 'No In Progress Requests';
        message = 'No maintenance requests currently in progress.';
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
        message = _selectedSpaceId == null
            ? 'No maintenance requests across all your spaces.'
            : 'No maintenance requests for this space.';
        icon = Icons.build_circle_outlined;
        color = AppTheme.landlordColor;
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 400,
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
