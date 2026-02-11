import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/space_details_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/space_card.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpacesListScreen extends ConsumerStatefulWidget {
  const SpacesListScreen({super.key});

  @override
  ConsumerState<SpacesListScreen> createState() => _SpacesListScreenState();
}

class _SpacesListScreenState extends ConsumerState<SpacesListScreen> {
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    // Load spaces when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spacesProvider.notifier).loadSpaces();
    });
  }

  // ✅ Pull-to-refresh handler
  Future<void> _handleRefresh() async {
    await ref.read(spacesProvider.notifier).loadSpaces();
  }

  Future<void> _showCreateSpaceDialog() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Space'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Space Name',
                hintText: 'e.g., Sunset Apartments',
                prefixIcon: Icon(Icons.business),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            Text(
              'A unique join code will be generated automatically.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
            child: const Text('Create'),
          ),
        ],
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    nameController.dispose();

    if (result != null && mounted) {
      setState(() => _isCreating = true);
      
      try {
        final newSpace = await ref.read(spacesProvider.notifier).createSpace(result);
        
        if (mounted && newSpace != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Space created successfully!'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join Code: ${newSpace.joinCode}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create space: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCreating = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final spacesState = ref.watch(spacesProvider);
    final spaces = spacesState.spaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Spaces'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh, // ✅ Pull-to-refresh
        child: spacesState.isLoading && spaces.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : spaces.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    itemCount: spaces.length,
                    itemBuilder: (context, index) {
                      final space = spaces[index];
                      return SpaceCard(
                        space: space,
                        onTap: () async {
                          // ✅ Refresh on return from details
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpaceDetailsScreen(space: space),
                            ),
                          );
                          
                          // If space was updated/deleted, refresh list
                          if (result == true && mounted) {
                            ref.read(spacesProvider.notifier).loadSpaces();
                          }
                        },
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _showCreateSpaceDialog,
        backgroundColor: AppTheme.landlordColor,
        icon: _isCreating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add),
        label: const Text('Create Space'),
      ),
    );
  }

  Widget _buildEmptyState() {
    // ✅ Make empty state refreshable too
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
                      child: const Icon(
                        Icons.business,
                        size: 64,
                        color: AppTheme.landlordColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Spaces Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first space to start managing your apartment building.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _showCreateSpaceDialog,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Create Your First Space'),
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