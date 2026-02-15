import 'package:apartment_app/features/tenant/data/models/maintenance_request_model.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class UpdateStatusDialog extends StatefulWidget {
  final MaintenanceStatus currentStatus;

  const UpdateStatusDialog({
    super.key,
    required this.currentStatus,
  });

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  late MaintenanceStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  Color _getStatusColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return AppTheme.warningColor;
      case MaintenanceStatus.inProgress:
        return AppTheme.primaryColor;
      case MaintenanceStatus.completed:
        return AppTheme.successColor;
      case MaintenanceStatus.cancelled:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.pending:
        return Icons.pending_outlined;
      case MaintenanceStatus.inProgress:
        return Icons.construction_outlined;
      case MaintenanceStatus.completed:
        return Icons.check_circle_outline;
      case MaintenanceStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select new status:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          
          // Status Options
          ...MaintenanceStatus.values.map((status) {
            final isSelected = _selectedStatus == status;
            final color = _getStatusColor(status);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.1) : null,
                    border: Border.all(
                      color: isSelected ? color : AppTheme.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: isSelected ? color : AppTheme.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          status.displayName,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: isSelected ? color : null,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: color,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedStatus == widget.currentStatus
              ? null
              : () => Navigator.pop(context, _selectedStatus),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.landlordColor,
          ),
          child: const Text('Update'),
        ),
      ],
    );
  }
}