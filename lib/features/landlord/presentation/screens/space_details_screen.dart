import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/rooms_list_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/pending_requests_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/active_members_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/audit_logs_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/space_maintenance_screen.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/space_model.dart';

class SpaceDetailsScreen extends ConsumerStatefulWidget {
  final Space space;

  const SpaceDetailsScreen({
    super.key,
    required this.space,
  });

  @override
  ConsumerState<SpaceDetailsScreen> createState() => _SpaceDetailsScreenState();
}

class _SpaceDetailsScreenState extends ConsumerState<SpaceDetailsScreen> {
  bool _isUpdating = false;
  bool _isDeleting = false;
  late Space _currentSpace;

  @override
  void initState() {
    super.initState();
    _currentSpace = widget.space;
  }

  // Pull-to-refresh: Fetch latest space details
  Future<void> _handleRefresh() async {
    try {
      // Reload all spaces to get latest data
      await ref.read(spacesProvider.notifier).loadSpaces();
      
      // Find updated space in the list
      final spacesState = ref.read(spacesProvider);
      final updatedSpace = spacesState.spaces.firstWhere(
        (s) => s.id == widget.space.id,
        orElse: () => widget.space,
      );
      
      if (mounted) {
        setState(() {
          _currentSpace = updatedSpace;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _copyJoinCode() {
    Clipboard.setData(ClipboardData(text: _currentSpace.joinCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('Copied: ${_currentSpace.joinCode}'),
          ],
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showEditNameDialog() async {
    final nameController = TextEditingController(text: _currentSpace.name);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Space Name'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Space Name',
            prefixIcon: Icon(Icons.business),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a space name')),
                );
                return;
              }
              if (name.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name must be at least 3 characters')),
                );
                return;
              }
              Navigator.pop(context, name);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    nameController.dispose();

    if (result != null && result != _currentSpace.name && mounted) {
      setState(() => _isUpdating = true);

      try {
        await ref.read(spacesProvider.notifier).updateSpaceName(
              _currentSpace.id,
              result,
            );

        if (mounted) {
          setState(() {
            _currentSpace = _currentSpace.copyWith(name: result);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Space name updated'),
                ],
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
          
          Navigator.pop(context, true);
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
              content: Text('Failed to update space: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUpdating = false);
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Space'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to delete this space?'),
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
                      'This action cannot be undone. All units and memberships will be deleted.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);

      try {
        await ref.read(spacesProvider.notifier).deleteSpace(_currentSpace.id);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Space deleted'),
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
              content: Text('Failed to delete space: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSpace.name),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.landlordColor.withOpacity(0.1),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppTheme.landlordColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentSpace.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Space Information Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.landlordColor),
                            const SizedBox(width: 12),
                            Text(
                              'Space Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(Icons.vpn_key_outlined),
                        title: const Text('Join Code'),
                        subtitle: Text(
                          _currentSpace.joinCode,
                          style: const TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: _copyJoinCode,
                          tooltip: 'Copy',
                        ),
                      ),

                      ListTile(
                        leading: const Icon(Icons.tag_outlined),
                        title: const Text('Space ID'),
                        subtitle: Text(
                          _currentSpace.id,
                          style: const TextStyle(fontFamily: 'Courier'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Management Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.settings_outlined, color: AppTheme.landlordColor),
                            const SizedBox(width: 12),
                            Text(
                              'Management',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Rooms Management
                      ListTile(
                        leading: const Icon(Icons.door_front_door_outlined),
                        title: const Text('Units Management'),
                        subtitle: const Text('View and manage units'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomsListScreen(space: _currentSpace),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),

                      // Pending Requests
                      ListTile(
                        leading: const Icon(Icons.inbox_outlined, color: AppTheme.landlordColor),
                        title: const Text('Pending Requests'),
                        subtitle: const Text('Approve or reject join requests'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PendingRequestsScreen(space: _currentSpace),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),

                      // Active Members
                      ListTile(
                        leading: const Icon(Icons.people_outline, color: AppTheme.landlordColor),
                        title: const Text('Active Members'),
                        subtitle: const Text('View and manage tenants'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActiveMembersScreen(space: _currentSpace),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),


// 🆕 ADD THIS NEW MAINTENANCE SECTION
ListTile(
  leading: const Icon(Icons.build_circle_outlined, color: AppTheme.warningColor),
  title: const Text('Maintenance'),
  subtitle: const Text('View and manage maintenance requests'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpaceMaintenanceScreen(
          spaceId: _currentSpace.id,
          spaceName: _currentSpace.name,
        ),
      ),
    );
  },
),
const Divider(height: 1),

                      // ✅ Audit Logs (NOW ACTIVE!)
                      ListTile(
                        leading: const Icon(Icons.history_outlined, color: AppTheme.landlordColor),
                        title: const Text('Audit Logs'),
                        subtitle: const Text('View action history'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuditLogsScreen(space: _currentSpace),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Actions Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: const Text('Edit Space Name'),
                        trailing: _isUpdating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _isUpdating ? null : _showEditNameDialog,
                      ),
                      const Divider(height: 1),

                      ListTile(
                        leading: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                        title: const Text(
                          'Delete Space',
                          style: TextStyle(color: AppTheme.errorColor),
                        ),
                        trailing: _isDeleting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.chevron_right, color: AppTheme.errorColor),
                        onTap: _isDeleting ? null : _showDeleteConfirmation,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}