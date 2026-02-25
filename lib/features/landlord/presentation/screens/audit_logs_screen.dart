import 'package:apartment_app/features/landlord/data/models/space_model.dart';
import 'package:apartment_app/features/landlord/presentation/providers/audit_logs_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AuditLogsScreen extends ConsumerStatefulWidget {
  final Space space;

  const AuditLogsScreen({
    super.key,
    required this.space,
  });

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  String? _filterCategory;

  @override
  void initState() {
    super.initState();
    // Load audit logs when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(auditLogsProvider.notifier).loadAuditLogs(widget.space.id);
    });
  }

  // Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    await ref.read(auditLogsProvider.notifier).loadAuditLogs(widget.space.id);
  }

  // Load more handler
  void _handleLoadMore() {
    ref.read(auditLogsProvider.notifier).loadMoreAuditLogs(widget.space.id);
  }

  // Get color for action category
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'SPACE':
        return AppTheme.landlordColor;
      case 'ROOM':
        return const Color(0xFF8B5CF6); // Purple
      case 'MEMBERSHIP':
        return AppTheme.tenantColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  // Get icon for action
  IconData _getActionIcon(String action) {
    if (action.contains('CREATE')) return Icons.add_circle_outline;
    if (action.contains('UPDATE')) return Icons.edit_outlined;
    if (action.contains('DELETE')) return Icons.delete_outline;
    if (action.contains('APPROVE')) return Icons.check_circle_outline;
    if (action.contains('REJECT')) return Icons.cancel_outlined;
    if (action.contains('MOVE')) return Icons.swap_horiz;
    if (action.contains('JOIN')) return Icons.person_add_outlined;
    if (action.contains('LEAVE') || action.contains('REMOVE')) return Icons.person_remove_outlined;
    return Icons.info_outline;
  }

  @override
  Widget build(BuildContext context) {
    final auditLogsState = ref.watch(auditLogsProvider);
    final allLogs = auditLogsState.logs;
    
    // Filter logs by category
    final filteredLogs = _filterCategory == null
        ? allLogs
        : allLogs.where((log) => log.category == _filterCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Audit Logs - ${widget.space.name}'),
        actions: [
          // Filter menu
          PopupMenuButton<String?>(
            icon: Icon(
              _filterCategory != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _filterCategory != null ? AppTheme.landlordColor : null,
            ),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                _filterCategory = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 12),
                    Text('All Actions'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'SPACE',
                child: Row(
                  children: [
                    Icon(Icons.business, size: 20, color: AppTheme.landlordColor),
                    SizedBox(width: 12),
                    Text('Space Actions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ROOM',
                child: Row(
                  children: [
                    Icon(Icons.door_front_door_outlined, size: 20, color: Color(0xFF8B5CF6)),
                    SizedBox(width: 12),
                    Text('Unit Actions'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'MEMBERSHIP',
                child: Row(
                  children: [
                    Icon(Icons.people_outline, size: 20, color: AppTheme.tenantColor),
                    SizedBox(width: 12),
                    Text('Membership Actions'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: auditLogsState.isLoading && allLogs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : filteredLogs.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      // Filter chip (if active)
                      if (_filterCategory != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Chip(
                                avatar: const Icon(Icons.filter_alt, size: 16),
                                label: Text('${_filterCategory!} Actions'),
                                onDeleted: () {
                                  setState(() {
                                    _filterCategory = null;
                                  });
                                },
                                deleteIcon: const Icon(Icons.close, size: 16),
                              ),
                              const Spacer(),
                              Text(
                                '${filteredLogs.length} of ${allLogs.length}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),

                      // Logs list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: filteredLogs.length + (auditLogsState.hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            // "Load More" button at the end
                            if (index == filteredLogs.length) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: auditLogsState.isLoadingMore
                                      ? const CircularProgressIndicator()
                                      : ElevatedButton.icon(
                                          onPressed: _handleLoadMore,
                                          icon: const Icon(Icons.expand_more),
                                          label: const Text('Load More'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.landlordColor.withOpacity(0.1),
                                            foregroundColor: AppTheme.landlordColor,
                                          ),
                                        ),
                                ),
                              );
                            }

                            final log = filteredLogs[index];
                            final categoryColor = _getCategoryColor(log.category);
                            final icon = _getActionIcon(log.action);

                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    icon,
                                    color: categoryColor,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  log.displayAction,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (log.details.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        log.details,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(log.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: categoryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    log.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _filterCategory != null;
    
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
                      child: Icon(
                        hasFilter ? Icons.filter_alt_off : Icons.history_outlined,
                        size: 64,
                        color: AppTheme.landlordColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      hasFilter ? 'No Logs Found' : 'No Audit Logs',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasFilter
                          ? 'No logs match the selected filter. Try clearing the filter.'
                          : 'All actions in this space will be logged here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (hasFilter) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _filterCategory = null;
                          });
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear Filter'),
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday at ${DateFormat.jm().format(timestamp)}';
    } else if (difference.inDays < 7) {
      // This week
      return '${difference.inDays}d ago';
    } else {
      // Older - show full date
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }
}