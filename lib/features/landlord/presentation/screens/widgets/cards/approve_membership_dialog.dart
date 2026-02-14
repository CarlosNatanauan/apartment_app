import 'package:apartment_app/features/landlord/data/models/room_model.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:apartment_app/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ApprovalData {
  final String roomId;
  final int monthlyRent;
  final DateTime rentStartDate;
  final int paymentDueDay;

  ApprovalData({
    required this.roomId,
    required this.monthlyRent,
    required this.rentStartDate,
    required this.paymentDueDay,
  });
}

class ApproveMembershipDialog extends StatefulWidget {
  final List<Room> availableRooms;
  final String tenantEmail;

  const ApproveMembershipDialog({
    super.key,
    required this.availableRooms,
    required this.tenantEmail,
  });

  @override
  State<ApproveMembershipDialog> createState() => _ApproveMembershipDialogState();
}

class _ApproveMembershipDialogState extends State<ApproveMembershipDialog> {
  final _formKey = GlobalKey<FormState>();
  
  String? _selectedRoomId;
  final TextEditingController _rentController = TextEditingController();
  DateTime? _rentStartDate;
  int? _paymentDueDay;

  @override
  void dispose() {
    _rentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _rentStartDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.landlordColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _rentStartDate = picked;
      });
    }
  }

  bool _canSubmit() {
    return _selectedRoomId != null &&
           _rentController.text.isNotEmpty &&
           _rentStartDate != null &&
           _paymentDueDay != null;
  }

  void _handleSubmit() {
    // Validate room selection
    if (_selectedRoomId == null) {
      _showError('Please select a room');
      return;
    }

    // Validate rent amount
    if (_rentController.text.isEmpty) {
      _showError('Please enter monthly rent amount');
      return;
    }

    final monthlyRent = CurrencyFormatter.parseToCents(_rentController.text);
    if (monthlyRent == null || monthlyRent <= 0) {
      _showError('Please enter a valid rent amount greater than 0');
      return;
    }

    // Validate rent start date
    if (_rentStartDate == null) {
      _showError('Please select rent start date');
      return;
    }

    // Validate payment due day
    if (_paymentDueDay == null) {
      _showError('Please select payment due day');
      return;
    }

    // All validations passed
    Navigator.pop(
      context,
      ApprovalData(
        roomId: _selectedRoomId!,
        monthlyRent: monthlyRent,
        rentStartDate: _rentStartDate!,
        paymentDueDay: _paymentDueDay!,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _canSubmit();

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Approve Membership'),
          const SizedBox(height: 4),
          Text(
            widget.tenantEmail,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Required Fields Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.landlordColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.landlordColor.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, 
                         size: 18, 
                         color: AppTheme.landlordColor),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All fields are required to approve membership',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.landlordColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Room Selection
              Text(
                'Room Assignment *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRoomId,
                decoration: InputDecoration(
                  hintText: 'Select a room',
                  prefixIcon: const Icon(Icons.door_front_door_outlined),
                  errorText: _selectedRoomId == null ? null : null,
                ),
                items: widget.availableRooms.map((room) {
                  return DropdownMenuItem(
                    value: room.id,
                    child: Text('Room ${room.roomNumber}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedRoomId = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Room is required';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Monthly Rent
              Text(
                'Monthly Rent *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rentController,
                decoration: const InputDecoration(
                  hintText: '500.00',
                  prefixIcon: Icon(Icons.attach_money),
                  helperText: 'Enter amount in dollars',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Monthly rent is required';
                  }
                  final cents = CurrencyFormatter.parseToCents(value);
                  if (cents == null || cents <= 0) {
                    return 'Enter valid amount greater than 0';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 20),

              // Rent Start Date
              Text(
                'Rent Start Date *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.calendar_today),
                    helperText: 'When rent payments begin',
                    errorText: _rentStartDate == null 
                        ? null 
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _rentStartDate != null
                            ? DateFormatter.formatDate(_rentStartDate)
                            : 'Tap to select date',
                        style: TextStyle(
                          color: _rentStartDate != null
                              ? AppTheme.textPrimary
                              : AppTheme.textHint,
                        ),
                      ),
                      if (_rentStartDate == null)
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.textHint,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Payment Due Day
              Text(
                'Payment Due Day *',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _paymentDueDay,
                decoration: const InputDecoration(
                  hintText: 'Select day of month',
                  prefixIcon: Icon(Icons.event),
                  helperText: 'Day of month (1-31)',
                ),
                items: List.generate(31, (index) => index + 1).map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text('${day}${_getDaySuffix(day)} of month'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentDueDay = value;
                  });
                },
                validator: (value) {
                  if (value == null) return 'Payment due day is required';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: canSubmit ? _handleSubmit : null,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Approve'),
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit ? AppTheme.successColor : AppTheme.textHint,
            disabledBackgroundColor: AppTheme.textHint,
          ),
        ),
      ],
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}