import 'package:apartment_app/features/landlord/data/models/room_model.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RoomSelectorDialog extends StatefulWidget {
  final List<Room> availableRooms;
  final String title;

  const RoomSelectorDialog({
    super.key,
    required this.availableRooms,
    this.title = 'Select Unit',
  });

  @override
  State<RoomSelectorDialog> createState() => _RoomSelectorDialogState();
}

class _RoomSelectorDialogState extends State<RoomSelectorDialog> {
  String? _selectedRoomId;

  @override
  Widget build(BuildContext context) {
    if (widget.availableRooms.isEmpty) {
      return AlertDialog(
        title: Text(widget.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.door_front_door_outlined,
                size: 48,
                color: AppTheme.warningColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Available Units',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'All units in this space are currently occupied. Please add more units or wait for a unit to become available.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(widget.title),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an available unit to assign:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            
            // Room Grid - Fixed overflow issue
            Flexible(
              child: SizedBox(
                height: 280,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: widget.availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = widget.availableRooms[index];
                    final isSelected = _selectedRoomId == room.id;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedRoomId = room.id;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.landlordColor
                              : AppTheme.landlordColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.landlordColor
                                : AppTheme.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Main content - centered
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.door_front_door_outlined,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.landlordColor,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  room.roomNumber,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            // Check icon overlay - positioned in top right corner
                            if (isSelected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: AppTheme.landlordColor,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRoomId == null
              ? null
              : () => Navigator.pop(context, _selectedRoomId),
          child: const Text('Assign Unit'),
        ),
      ],
    );
  }
}