import 'package:apartment_app/features/landlord/presentation/providers/notices_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateNoticeDialog extends ConsumerStatefulWidget {
  final String spaceId;

  const CreateNoticeDialog({
    super.key,
    required this.spaceId,
  });

  @override
  ConsumerState<CreateNoticeDialog> createState() => _CreateNoticeDialogState();
}

class _CreateNoticeDialogState extends ConsumerState<CreateNoticeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  DateTime? _expiresAt;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _selectExpiryDate() async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = DateTime(now.year + 1);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
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

    if (pickedDate != null) {
      setState(() {
        _expiresAt = pickedDate;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await ref.read(noticesProvider.notifier).createNotice(
        spaceId: widget.spaceId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        expiresAt: _expiresAt,
      );

      if (mounted) {
        Navigator.pop(context, true); // Return success
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Announcement posted successfully!'),
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
            content: Text('Failed to post announcement: $e'),
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
          Icon(Icons.campaign, color: AppTheme.landlordColor),
          SizedBox(width: 8),
          Text('New Announcement'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Water shut off this Saturday',
                  prefixIcon: Icon(Icons.title),
                ),
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isSubmitting,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Content field
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Enter announcement details...',
                  prefixIcon: Icon(Icons.message),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isSubmitting,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  if (value.trim().length < 5) {
                    return 'Message must be at least 5 characters';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Expiry date section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Expiry Date (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_expiresAt == null) ...[
                      Text(
                        'This announcement will never expire',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _selectExpiryDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Set Expiry Date'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Expires: ${_formatDate(_expiresAt!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() => _expiresAt = null),
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            color: AppTheme.errorColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _selectExpiryDate,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Change Date'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.landlordColor,
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
              : const Icon(Icons.send, size: 20),
          label: Text(_isSubmitting ? 'Posting...' : 'Post Announcement'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Helper function to show the dialog
Future<bool?> showCreateNoticeDialog({
  required BuildContext context,
  required String spaceId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => CreateNoticeDialog(spaceId: spaceId),
  );
}