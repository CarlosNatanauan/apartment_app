import 'dart:convert';
import 'dart:io';

import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/features/tenant/data/models/maintenance_request_model.dart';
import 'package:apartment_app/features/tenant/presentation/provider/maintenance_provider.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_memberships_provider.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class CreateMaintenanceScreen extends ConsumerStatefulWidget {
  const CreateMaintenanceScreen({super.key});

  @override
  ConsumerState<CreateMaintenanceScreen> createState() =>
      _CreateMaintenanceScreenState();
}

class _CreateMaintenanceScreenState
    extends ConsumerState<CreateMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _imagePicker = ImagePicker();

  MaintenanceCategory _selectedCategory = MaintenanceCategory.plumbing;
  String? _selectedMembershipId; // 🆕 NEW: Track selected membership
  XFile? _selectedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 🆕 Load memberships on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tenantMembershipsProvider.notifier).loadMemberships();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<String?> _convertImageToBase64() async {
    if (_selectedImage == null) return null;

    try {
      final bytes = await File(_selectedImage!.path).readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      print('❌ Failed to convert image: $e');
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // 🆕 Get selected membership (or first one if only one exists)
      final membershipsState = ref.read(tenantMembershipsProvider);
      final activeMemberships = membershipsState.activeMemberships;

      if (activeMemberships.isEmpty) {
        throw Exception('No active memberships found');
      }

      // Get the selected membership
      final selectedMembership = activeMemberships.length == 1
          ? activeMemberships.first
          : activeMemberships.firstWhere(
              (m) => m.id == _selectedMembershipId,
              orElse: () => throw Exception('Please select a space and room'),
            );

      // Validate spaceId and roomId exist
      if (selectedMembership.spaceId == null || selectedMembership.roomId == null) {
        throw Exception('Selected membership is missing space or room information');
      }

      // Convert image if present
      final imageData = await _convertImageToBase64();

      await ref.read(maintenanceProvider.notifier).createRequest(
            spaceId: selectedMembership.spaceId!, // 🆕 Pass spaceId
            roomId: selectedMembership.roomId!, // 🆕 Pass roomId
            category: _selectedCategory,
            customCategory: _selectedCategory == MaintenanceCategory.other
                ? _customCategoryController.text.trim()
                : null,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            imageData: imageData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Request created successfully'),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate back
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create request: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Watch memberships state
    final membershipsState = ref.watch(tenantMembershipsProvider);
    final activeMemberships = membershipsState.activeMemberships;
    final isLoadingMemberships = membershipsState.isLoading;

    // 🆕 Show loading while memberships are being fetched
    if (isLoadingMemberships && activeMemberships.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('New Maintenance Request'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 🆕 Show error if no active memberships
    if (activeMemberships.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('New Maintenance Request'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.warning_outlined,
                  size: 64,
                  color: AppTheme.warningColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Active Memberships',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'You need to join a space before creating maintenance requests.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Maintenance Request'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 🆕 NEW: Space/Room Selector (ONLY if multiple active memberships)
            if (activeMemberships.length > 1) ...[
              Text(
                'Select Space & Room',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMembershipId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.apartment),
                  hintText: 'Select space and room',
                ),
                items: activeMemberships.map((membership) {
                  return DropdownMenuItem(
                    value: membership.id,
                    child: Text(
                      '${membership.spaceName ?? 'Unknown'} - Room ${membership.roomNumber ?? 'N/A'}',
                    ),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedMembershipId = value;
                        });
                      },
                validator: (value) {
                  if (activeMemberships.length > 1 && value == null) {
                    return 'Please select a space and room';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // 🆕 Show selected space info if only one membership
            if (activeMemberships.length == 1) ...[
              Card(
                color: AppTheme.tenantColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.apartment,
                        color: AppTheme.tenantColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reporting for:',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              '${activeMemberships.first.spaceName ?? 'Unknown'} - Room ${activeMemberships.first.roomNumber ?? 'N/A'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Category Dropdown
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<MaintenanceCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_outlined),
                hintText: 'Select category',
              ),
              items: MaintenanceCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                          // Clear custom category if switching away from Other
                          if (value != MaintenanceCategory.other) {
                            _customCategoryController.clear();
                          }
                        });
                      }
                    },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),

            // Custom Category (shown when Other is selected)
            if (_selectedCategory == MaintenanceCategory.other) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _customCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Custom Category',
                  hintText: 'Enter category name',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                enabled: !_isSubmitting,
                validator: (value) {
                  if (_selectedCategory == MaintenanceCategory.other) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a custom category';
                    }
                    if (value.trim().length < 3) {
                      return 'Category must be at least 3 characters';
                    }
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),

            // Title
            Text(
              'Title',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Brief description of the issue',
                prefixIcon: Icon(Icons.title_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: !_isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                if (value.trim().length > 100) {
                  return 'Title must not exceed 100 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Detailed description of the issue',
                prefixIcon: Icon(Icons.description_outlined),
                alignLabelWithHint: true,
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 5,
              enabled: !_isSubmitting,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                if (value.trim().length > 1000) {
                  return 'Description must not exceed 1000 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Image Upload (Optional)
            Text(
              'Photo (Optional)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  if (_selectedImage == null) ...[
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: AppTheme.textHint,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a photo of the issue',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImage,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose Photo'),
                    ),
                  ] else ...[
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_selectedImage!.path),
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _isSubmitting ? null : _pickImage,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Change Photo'),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tenantColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Request'),
              ),
            ),

            const SizedBox(height: 16),

            // Help text
            Center(
              child: Text(
                'Your request will be sent to the landlord',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}