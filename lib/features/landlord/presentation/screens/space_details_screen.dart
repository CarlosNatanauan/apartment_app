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
import 'package:qr_flutter/qr_flutter.dart';
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

  void _showJoinCodeQrDialog() {
    final joinCode = _currentSpace.joinCode;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join Code QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: QrImageView(
                data: joinCode,
                version: QrVersions.auto,
                size: 220,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              joinCode,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tenants can scan this to join',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: joinCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copied'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Code'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

  Widget _manageTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textHint),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSpace.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit name',
            onPressed: _isUpdating ? null : _showEditNameDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Join Code Banner
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1E40AF), AppTheme.landlordColor],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.landlordColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.vpn_key_outlined, size: 14, color: Colors.white70),
                          SizedBox(width: 6),
                          Text(
                            'Join Code',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _currentSpace.joinCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                          const Spacer(),
                          _CodeActionButton(
                            icon: Icons.qr_code,
                            tooltip: 'Show QR',
                            onTap: _showJoinCodeQrDialog,
                          ),
                          const SizedBox(width: 8),
                          _CodeActionButton(
                            icon: Icons.copy_outlined,
                            tooltip: 'Copy code',
                            onTap: _copyJoinCode,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share this code with tenants to join your space',
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 4),

              // Manage section
              const _SectionLabel('Manage'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _manageTile(
                      icon: Icons.door_front_door_outlined,
                      title: 'Units',
                      subtitle: 'View and manage rooms',
                      color: AppTheme.landlordColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomsListScreen(space: _currentSpace),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _manageTile(
                      icon: Icons.inbox_outlined,
                      title: 'Pending Requests',
                      subtitle: 'Approve or reject join requests',
                      color: AppTheme.warningColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PendingRequestsScreen(space: _currentSpace),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _manageTile(
                      icon: Icons.people_outline,
                      title: 'Active Members',
                      subtitle: 'View and manage tenants',
                      color: AppTheme.successColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ActiveMembersScreen(space: _currentSpace),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _manageTile(
                      icon: Icons.build_circle_outlined,
                      title: 'Maintenance',
                      subtitle: 'View and manage requests',
                      color: AppTheme.warningColor,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SpaceMaintenanceScreen(
                            spaceId: _currentSpace.id,
                            spaceName: _currentSpace.name,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1, indent: 56),
                    _manageTile(
                      icon: Icons.history_outlined,
                      title: 'Audit Logs',
                      subtitle: 'View action history',
                      color: AppTheme.textSecondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AuditLogsScreen(space: _currentSpace),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Settings section
              const _SectionLabel('Settings'),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.landlordColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.landlordColor,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Edit Space Name',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                  ),
                  trailing: _isUpdating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right, size: 18, color: AppTheme.textHint),
                  onTap: _isUpdating ? null : _showEditNameDialog,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
              ),

              const SizedBox(height: 16),

              // Danger Zone
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 8),
                      child: Text(
                        'DANGER ZONE',
                        style: TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppTheme.errorColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: AppTheme.errorColor.withValues(alpha: 0.03),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.errorColor,
                            size: 20,
                          ),
                        ),
                        title: const Text(
                          'Delete Space',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: const Text('Permanently removes this space'),
                        trailing: _isDeleting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.errorColor,
                                ),
                              )
                            : const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppTheme.errorColor,
                              ),
                        onTap: _isDeleting ? null : _showDeleteConfirmation,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _CodeActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _CodeActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}