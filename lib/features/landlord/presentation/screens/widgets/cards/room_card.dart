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
    // ✅ Dynamic colors based on occupancy
    final statusColor = room.isOccupied ? AppTheme.errorColor : AppTheme.successColor;
    final statusText = room.isOccupied ? 'Occupied' : 'Available';
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Room Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),  // ✅ Dynamic color
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.door_front_door_outlined,
                  size: 28,
                  color: statusColor,  // ✅ Dynamic color
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Room Number
              Flexible(
                child: Text(
                  room.roomNumber,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // ✅ Dynamic Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              // 🆕 NEW: Show tenant email if occupied
              if (room.isOccupied && room.occupiedBy != null) ...[
                const SizedBox(height: 4),
                Text(
                  room.occupiedBy!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      color: AppTheme.landlordColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 8),
                  
                  // Delete Button (disabled if occupied)
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: room.isOccupied ? null : onDelete,  // ✅ Disable if occupied
                      tooltip: room.isOccupied ? 'Cannot delete occupied room' : 'Delete',
                      color: room.isOccupied ? AppTheme.textHint : AppTheme.errorColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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