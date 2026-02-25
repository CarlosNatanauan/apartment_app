import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RequestRoomDialog extends ConsumerStatefulWidget {
  final String spaceId;
  final String spaceName;
  final List<String> currentRoomIds; // Room IDs tenant already has

  const RequestRoomDialog({
    super.key,
    required this.spaceId,
    required this.spaceName,
    required this.currentRoomIds,
  });

  @override
  ConsumerState<RequestRoomDialog> createState() => _RequestRoomDialogState();
}

class _RequestRoomDialogState extends ConsumerState<RequestRoomDialog> {
  List<Room>? _rooms;
  bool _isLoading = true;
  String? _error;
  String? _selectedRoomId;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final response = await apiClient.get(
        '/spaces/${widget.spaceId}/rooms',
        fromJson: (data) {
          if (data is Map && data.containsKey('data')) {
            final items = data['data'] as List? ?? [];
            return items
                .map((json) => Room.fromJson(json as Map<String, dynamic>))
                .toList();
          } else if (data is List) {
            return data
                .map((json) => Room.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return <Room>[];
        },
      );

      if (mounted) {
        setState(() {
          _rooms = response.data;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load rooms';
          _isLoading = false;
        });
      }
    }
  }

  List<Room> get _availableRooms {
    if (_rooms == null) return [];
    
    // Filter out rooms tenant already has (active, pending, or rejected leases)
    return _rooms!
        .where((room) => !widget.currentRoomIds.contains(room.id))
        .toList();
  }

  void _handleSubmit() {
    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a unit'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    Navigator.of(context).pop(_selectedRoomId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request Another Unit'),
          const SizedBox(height: 4),
          Text(
            widget.spaceName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.errorColor),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _loadRooms,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _availableRooms.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.meeting_room_outlined,
                                size: 48,
                                color: AppTheme.textHint,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No available units',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You have already requested or occupy all units in this space.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableRooms.length,
                        itemBuilder: (context, index) {
                          final room = _availableRooms[index];
                          final isSelected = _selectedRoomId == room.id;
                          final isOccupied = room.isOccupied;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isSelected
                                ? AppTheme.tenantColor.withOpacity(0.1)
                                : null,
                            child: InkWell(
                              onTap: isOccupied
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedRoomId = room.id;
                                      });
                                    },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isOccupied
                                            ? AppTheme.textHint.withOpacity(0.1)
                                            : isSelected
                                                ? AppTheme.tenantColor.withOpacity(0.2)
                                                : AppTheme.tenantColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        isOccupied
                                            ? Icons.lock_outline
                                            : Icons.meeting_room_outlined,
                                        color: isOccupied
                                            ? AppTheme.textHint
                                            : AppTheme.tenantColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Unit ${room.roomNumber}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: isOccupied
                                                  ? AppTheme.textHint
                                                  : null,
                                            ),
                                          ),
                                          if (isOccupied) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              'Occupied',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textHint,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppTheme.tenantColor,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!_isLoading && _error == null && _availableRooms.isNotEmpty)
          ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tenantColor,
            ),
            child: const Text('Request'),
          ),
      ],
    );
  }
}

// Simple Room model for dialog
class Room {
  final String id;
  final String roomNumber;
  final bool isOccupied;
  final String? occupantName;

  Room({
    required this.id,
    required this.roomNumber,
    this.isOccupied = false,
    this.occupantName,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String? ?? json['roomId'] as String,
      roomNumber: json['roomNumber']?.toString() ?? '',
      isOccupied: json['isOccupied'] as bool? ?? false,
      occupantName: json['occupiedBy'] as String?,
    );
  }
}