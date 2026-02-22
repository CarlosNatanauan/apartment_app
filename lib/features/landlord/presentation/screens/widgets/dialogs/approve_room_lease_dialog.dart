import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ApproveRoomLeaseDialog extends StatefulWidget {
  final String roomNumber;
  final String tenantName;

  const ApproveRoomLeaseDialog({
    super.key,
    required this.roomNumber,
    required this.tenantName,
  });

  @override
  State<ApproveRoomLeaseDialog> createState() => _ApproveRoomLeaseDialogState();
}

class _ApproveRoomLeaseDialogState extends State<ApproveRoomLeaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _rentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int _selectedDueDay = 1;

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) return;

    final rentText = _rentController.text.trim().replaceAll(',', '');
    final monthlyRent = int.tryParse(rentText);

    if (monthlyRent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid rent amount'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // Return the approval data
    Navigator.of(context).pop({
      'monthlyRent': monthlyRent * 100, // Convert to cents
      'rentStartDate': _selectedDate,
      'paymentDueDay': _selectedDueDay,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Approve Room Lease'),
          const SizedBox(height: 4),
          Text(
            '${widget.tenantName} • Room ${widget.roomNumber}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Monthly Rent
              TextFormField(
                controller: _rentController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(7),
                ],
                decoration: const InputDecoration(
                  labelText: 'Monthly Rent',
                  hintText: 'e.g., 50000',
                  prefixText: '₱ ',
                  helperText: 'Amount in pesos',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter monthly rent';
                  }
                  final amount = int.tryParse(value.trim());
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Rent Start Date
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Rent Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    DateFormatter.formatDate(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Payment Due Day
              DropdownButtonFormField<int>(
                value: _selectedDueDay,
                decoration: const InputDecoration(
                  labelText: 'Payment Due Day',
                  helperText: 'Day of month when rent is due',
                ),
                items: List.generate(28, (index) {
                  final day = index + 1;
                  String suffix = 'th';
                  if (day == 1 || day == 21) suffix = 'st';
                  if (day == 2 || day == 22) suffix = 'nd';
                  if (day == 3 || day == 23) suffix = 'rd';

                  return DropdownMenuItem(
                    value: day,
                    child: Text('$day$suffix of each month'),
                  );
                }),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedDueDay = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.landlordColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppTheme.landlordColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Lease Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.landlordColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ${widget.tenantName} will occupy Room ${widget.roomNumber}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• Rent starts ${DateFormatter.formatDate(_selectedDate)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '• Monthly payment due on day $_selectedDueDay',
                      style: const TextStyle(fontSize: 12),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.successColor,
          ),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}