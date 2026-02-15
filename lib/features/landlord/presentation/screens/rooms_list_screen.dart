// rooms_list_screen.dart ✅ LIST (no grid overflows), same logic + dialogs
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/landlord/presentation/providers/rooms_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/widgets/cards/room_card.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/space_model.dart';

class RoomsListScreen extends ConsumerStatefulWidget {
  final Space space;

  const RoomsListScreen({super.key, required this.space});

  @override
  ConsumerState<RoomsListScreen> createState() => _RoomsListScreenState();
}

class _RoomsListScreenState extends ConsumerState<RoomsListScreen> {
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(roomsProvider.notifier).loadRooms(widget.space.id);
    });
  }

  Future<void> _handleRefresh() async {
    await ref.read(roomsProvider.notifier).loadRooms(widget.space.id);
  }

  Future<void> _showCreateRoomDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _CreateRoomDialog(
        spaceId: widget.space.id,
        onCreated: () {
          ref.read(roomsProvider.notifier).loadRooms(widget.space.id);
        },
      ),
    );
  }

  Future<void> _showEditRoomDialog(String roomId, String currentNumber) async {
    final numberController = TextEditingController(text: currentNumber);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Room Number'),
        content: TextField(
          controller: numberController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: const InputDecoration(
            labelText: 'Room Number',
            hintText: 'e.g., 101',
            prefixIcon: Icon(Icons.door_front_door_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final number = numberController.text.trim();

              if (number.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a room number')),
                );
                return;
              }

              if (!RegExp(r'^\d+$').hasMatch(number)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room number must be numeric')),
                );
                return;
              }
              Navigator.pop(context, number);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    await Future.delayed(const Duration(milliseconds: 100));
    numberController.dispose();

    if (result != null && result != currentNumber && mounted) {
      try {
        await ref
            .read(roomsProvider.notifier)
            .updateRoomNumber(widget.space.id, roomId, result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Room number updated'),
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
              content: Text('Failed to update room: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteConfirmation(String roomId, String roomNumber) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete room $roomNumber?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withOpacity(0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'If this room is occupied, deletion will fail.',
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
      try {
        await ref
            .read(roomsProvider.notifier)
            .deleteRoom(widget.space.id, roomId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Room deleted'),
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
              content: Text('Failed to delete room: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(roomsProvider);
    final rooms = roomsState.rooms;

    return Scaffold(
      appBar: AppBar(title: Text('Rooms - ${widget.space.name}')),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: roomsState.isLoading && rooms.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : rooms.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                itemCount: rooms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 0),
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return RoomCard(
                    room: room,
                    onEdit: () => _showEditRoomDialog(room.id, room.roomNumber),
                    onDelete: () =>
                        _showDeleteConfirmation(room.id, room.roomNumber),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCreating ? null : _showCreateRoomDialog,
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
        label: const Text('Add Room'),
      ),
    );
  }

  Widget _buildEmptyState() {
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
                        Icons.door_front_door_outlined,
                        size: 64,
                        color: AppTheme.landlordColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No Rooms Yet',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add rooms to this space to start managing tenants.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isCreating ? null : _showCreateRoomDialog,
                      icon: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Add Your First Room'),
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

// ✅ unchanged dialog (same theme + logic)
class _CreateRoomDialog extends ConsumerStatefulWidget {
  final String spaceId;
  final VoidCallback onCreated;

  const _CreateRoomDialog({required this.spaceId, required this.onCreated});

  @override
  ConsumerState<_CreateRoomDialog> createState() => _CreateRoomDialogState();
}

class _CreateRoomDialogState extends ConsumerState<_CreateRoomDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _singleController = TextEditingController();
  final _startController = TextEditingController();
  final _endController = TextEditingController();
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _singleController.dispose();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _createSingleRoom() async {
    final roomNumber = _singleController.text.trim();

    if (roomNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a room number')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      await ref
          .read(roomsProvider.notifier)
          .createRoom(widget.spaceId, roomNumber);

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room $roomNumber created successfully'),
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
            content: Text('Failed to create room: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _createBulkRooms() async {
    final startStr = _startController.text.trim();
    final endStr = _endController.text.trim();

    if (startStr.isEmpty || endStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter start and end numbers')),
      );
      return;
    }

    final start = int.tryParse(startStr);
    final end = int.tryParse(endStr);

    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numbers')),
      );
      return;
    }

    if (start >= end) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Start must be less than end')),
      );
      return;
    }

    if (end - start > 50) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 50 rooms at once')));
      return;
    }

    final roomNumbers = List.generate(
      end - start + 1,
      (index) => (start + index).toString(),
    );

    setState(() => _isCreating = true);

    try {
      await ref
          .read(roomsProvider.notifier)
          .createRooms(widget.spaceId, roomNumbers);

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${roomNumbers.length} rooms created successfully'),
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
            content: Text('Failed to create rooms: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Room'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.landlordColor,
              unselectedLabelColor: AppTheme.textHint,
              indicatorColor: AppTheme.landlordColor,
              tabs: const [
                Tab(text: 'Single'),
                Tab(text: 'Bulk'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: TabBarView(
                controller: _tabController,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _singleController,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Room Number',
                          hintText: 'e.g., 101',
                          prefixIcon: Icon(Icons.door_front_door_outlined),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _startController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Start Number',
                          hintText: 'e.g., 101',
                          prefixIcon: Icon(Icons.first_page),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _endController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'End Number',
                          hintText: 'e.g., 110',
                          prefixIcon: Icon(Icons.last_page),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Will create rooms from start to end (max 50)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isCreating ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isCreating
              ? null
              : () {
                  if (_tabController.index == 0) {
                    _createSingleRoom();
                  } else {
                    _createBulkRooms();
                  }
                },
          child: _isCreating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
