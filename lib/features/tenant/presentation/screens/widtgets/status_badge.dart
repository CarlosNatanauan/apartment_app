import 'package:apartment_app/features/tenant/data/models/maintenance_request_model.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final MaintenanceStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color _getBackgroundColor() {
    switch (status) {
      case MaintenanceStatus.pending:
        return AppTheme.warningColor.withOpacity(0.1);
      case MaintenanceStatus.inProgress:
        return AppTheme.primaryColor.withOpacity(0.1);
      case MaintenanceStatus.completed:
        return AppTheme.successColor.withOpacity(0.1);
      case MaintenanceStatus.cancelled:
        return AppTheme.textSecondary.withOpacity(0.1);
    }
  }

  Color _getTextColor() {
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

  IconData _getIcon() {
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: compact ? 14 : 16,
            color: _getTextColor(),
          ),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: TextStyle(
              color: _getTextColor(),
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}