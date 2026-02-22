import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/features/landlord/data/models/payment_models.dart';
import 'package:apartment_app/features/landlord/presentation/providers/payments_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MarkPaymentDialog extends ConsumerStatefulWidget {
  final String spaceId;
  final String leaseId;
  final String tenantName;
  final String roomNumber;
  final int amount;  // in cents
  final int? year;
  final int? month;

  const MarkPaymentDialog({
    super.key,
    required this.spaceId,
    required this.leaseId,
    required this.tenantName,
    required this.roomNumber,
    required this.amount,
    this.year,
    this.month,
  });

  @override
  ConsumerState<MarkPaymentDialog> createState() => _MarkPaymentDialogState();
}

class _MarkPaymentDialogState extends ConsumerState<MarkPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleMarkPaid() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final paymentsState = ref.read(paymentsProvider);
      
      // Use provided year/month or current period
      final year = widget.year ?? paymentsState.currentYear;
      final month = widget.month ?? paymentsState.currentMonth;
      
      await ref.read(paymentsProvider.notifier).markPaid(
        spaceId: widget.spaceId,
        leaseId: widget.leaseId,
        year: year,
        month: month,
        note: _noteController.text.trim().isEmpty 
            ? null 
            : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context, true); // Return success
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Payment marked as paid for ${widget.tenantName}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark payment: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle_outline, color: AppTheme.successColor),
          SizedBox(width: 8),
          Text('Mark Payment as Paid'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tenant info card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.tenantName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.door_front_door_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Room ${widget.roomNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Amount
              const Text(
                'Amount',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CurrencyFormatter.formatCents(widget.amount),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Note field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Payment Note (Optional)',
                  hintText: 'e.g., Cash payment received',
                  helperText: 'Add any relevant payment details',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
                enabled: !_isSubmitting,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
              ),
              
              const SizedBox(height: 8),
              
              // Info text
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.primaryColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This will mark the payment as received for the current period.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleMarkPaid,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check_circle, size: 20),
          label: Text(_isSubmitting ? 'Marking...' : 'Mark as Paid'),
        ),
      ],
    );
  }
}

// Helper function to show the dialog
Future<bool?> showMarkPaymentDialog({
  required BuildContext context,
  required String spaceId,
  required String leaseId,
  required String tenantName,
  required String roomNumber,
  required int amount,
  int? year,
  int? month,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => MarkPaymentDialog(
      spaceId: spaceId,
      leaseId: leaseId,
      tenantName: tenantName,
      roomNumber: roomNumber,
      amount: amount,
      year: year,
      month: month,
    ),
  );
}