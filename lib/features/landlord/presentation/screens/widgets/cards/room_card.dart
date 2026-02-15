// room_card.dart ✅ LIST layout (no overflow), same theme + same callbacks
import 'package:apartment_app/features/landlord/data/models/room_model.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const RoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor =
        room.isOccupied ? AppTheme.errorColor : AppTheme.successColor;
    final statusText = room.isOccupied ? 'Occupied' : 'Available';

    final occupantName = room.occupant?.displayName;
    final occupantEmail = room.occupant?.email;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Left icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.door_front_door_outlined,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Middle content (wrap-safe)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room number + badge row (wrap-safe)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Room ${room.roomNumber}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Occupant (2-line max, no overflow)
                    if (room.isOccupied) ...[
                      if (occupantName != null &&
                          occupantName.trim().isNotEmpty)
                        Text(
                          occupantName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (occupantEmail != null &&
                          occupantEmail.trim().isNotEmpty)
                        Text(
                          occupantEmail,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ] else ...[
                      Text(
                        'No occupant',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Right actions (never overflow)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      color: AppTheme.landlordColor,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: room.isOccupied ? null : onDelete,
                      tooltip: room.isOccupied
                          ? 'Cannot delete occupied room'
                          : 'Delete',
                      color:
                          room.isOccupied ? AppTheme.textHint : AppTheme.errorColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
