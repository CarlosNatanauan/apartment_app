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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),  // ✅ Reduced from 16
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,  // ✅ Added to prevent overflow
            children: [
              // Room Icon
              Container(
                padding: const EdgeInsets.all(10),  // ✅ Reduced from 12
                decoration: BoxDecoration(
                  color: AppTheme.landlordColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.door_front_door_outlined,
                  size: 28,  // ✅ Reduced from 32
                  color: AppTheme.landlordColor,
                ),
              ),
              
              const SizedBox(height: 8),  // ✅ Reduced from 12
              
              // Room Number (Large)
              Flexible(  // ✅ Wrapped in Flexible
                child: Text(
                  room.roomNumber,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,  // ✅ Slightly smaller
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,  // ✅ Prevent multi-line
                  overflow: TextOverflow.ellipsis,  // ✅ Handle long numbers
                ),
              ),
              
              const SizedBox(height: 6),  // ✅ Reduced from 8
              
              // Status Badge (Available)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),  // ✅ Reduced
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Available',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 11,  // ✅ Reduced from 12
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),  // ✅ Reduced from 12
              
              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,  // ✅ Added
                children: [
                  // Edit Button
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),  // ✅ Reduced from 20
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      color: AppTheme.landlordColor,
                      padding: EdgeInsets.zero,  // ✅ Reduced padding
                      constraints: const BoxConstraints(),  // ✅ Removed default constraints
                    ),
                  
                  if (onEdit != null && onDelete != null)
                    const SizedBox(width: 8),  // ✅ Spacing between buttons
                  
                  // Delete Button
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),  // ✅ Reduced from 20
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      color: AppTheme.errorColor,
                      padding: EdgeInsets.zero,  // ✅ Reduced padding
                      constraints: const BoxConstraints(),  // ✅ Removed default constraints
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