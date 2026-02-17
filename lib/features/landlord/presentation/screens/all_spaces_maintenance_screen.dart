import 'package:apartment_app/core/api/api_response.dart';
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
    setState(() {
      _selectedSpaceId = spaceId;
    });

    if (spaceId == null) {
      ref.read(landlordMaintenanceProvider.notifier).loadAllSpacesRequests();
    } else {
      ref.read(landlordMaintenanceProvider.notifier).loadSpaceRequests(spaceId);
    }
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

        // ✅ Match the other screens: same AppBar structure, but with a clean bottom area.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(116),
          child: Material(
            // keeps background consistent with AppBar theme
            color: Colors.transparent,
            child: Column(
              children: [
                // Space Filter Dropdown
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButtonFormField<String?>(
                    value: _selectedSpaceId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Filter by Space',
                      prefixIcon: const Icon(Icons.filter_list),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.25),
                        ),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(Icons.select_all, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'All Spaces',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      ...spaces.map((space) {
                        return DropdownMenuItem<String?>(
                          value: space.id,
                          child: Row(
                            children: [
                              const Icon(Icons.business, size: 20),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  space.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: _handleSpaceFilterChange,
                  ),
                ),

                // Tabs
                TabBar(
                  controller: _tabController,
                  labelColor: AppTheme.landlordColor,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.landlordColor,
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'All (${allRequests.length})'),
                    Tab(text: 'Pending (${pendingRequests.length})'),
                    Tab(text: 'In Progress (${inProgressRequests.length})'),
                    Tab(text: 'Completed (${completedRequests.length})'),
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

    switch (type) {
      case 'pending':
        title = 'No Pending Requests';
        message = 'No maintenance requests awaiting your response.';
        icon = Icons.pending_actions;
        break;
      case 'inprogress':
        title = 'No In Progress Requests';
        message = 'No maintenance requests currently in progress.';
        icon = Icons.construction;
        break;
      case 'completed':
        title = 'No Completed Requests';
        message = 'No completed maintenance requests yet.';
        icon = Icons.check_circle_outline;
        break;
      default:
        title = 'No Maintenance Requests';
        message = _selectedSpaceId == null
            ? 'No maintenance requests across all your spaces.'
            : 'No maintenance requests for this space.';
        icon = Icons.build_circle_outlined;
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
