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

  // ✅ NEW: roomId selector (not membershipId)
  String? _selectedRoomId;

  final List<XFile> _selectedImages = [];
  static const int _maxImages = 5;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImages() async {
    final remaining = _maxImages - _selectedImages.length;
    if (remaining <= 0) return;

    try {
      final picked = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked.isNotEmpty) {
        final toAdd = picked.take(remaining).toList();
        setState(() => _selectedImages.addAll(toAdd));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final membershipsState = ref.read(tenantMembershipsProvider);
      final activeMemberships = membershipsState.activeMemberships;

      // ✅ Build active room options from ALL active leases
      final activeRoomOptions = <_RoomOption>[];
      for (final m in activeMemberships) {
        for (final lease in m.activeLeases) {
          if (lease.roomId == null) continue;
          activeRoomOptions.add(
            _RoomOption(
              roomId: lease.roomId!,
              label:
                  '${m.spaceName ?? 'Space'} - Unit ${lease.roomNumber ?? 'N/A'}',
            ),
          );
        }
      }

      if (activeRoomOptions.isEmpty) {
        throw Exception(
          'You must have an active unit lease to create a maintenance request.',
        );
      }

      final roomId = activeRoomOptions.length == 1
          ? activeRoomOptions.first.roomId
          : activeRoomOptions.firstWhere(
              (o) => o.roomId == _selectedRoomId,
              orElse: () => throw Exception('Please select a unit'),
            ).roomId;

      final imageFiles = <File>[];
      for (final xFile in _selectedImages) {
        final file = File(xFile.path);
        final size = await file.length();
        if (size > 5 * 1024 * 1024) {
          throw Exception('Each image must be 5MB or less.');
        }
        imageFiles.add(file);
      }

      await ref.read(maintenanceProvider.notifier).createRequest(
            roomId: roomId,
            category: _selectedCategory,
            customCategory: _selectedCategory == MaintenanceCategory.other
                ? _customCategoryController.text.trim()
                : null,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            imageFiles: imageFiles,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(child: Text('Request created successfully')),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 2),
          ),
        );
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
    final membershipsState = ref.watch(tenantMembershipsProvider);
    final activeMemberships = membershipsState.activeMemberships;
    final isLoadingMemberships = membershipsState.isLoading;

    // ✅ Build active room options for UI
    final activeRoomOptions = <_RoomOption>[];
    for (final m in activeMemberships) {
      for (final lease in m.activeLeases) {
        if (lease.roomId == null) continue;
        activeRoomOptions.add(
          _RoomOption(
            roomId: lease.roomId!,
            label: '${m.spaceName ?? 'Space'} - Unit ${lease.roomNumber ?? 'N/A'}',
          ),
        );
      }
    }

    if (isLoadingMemberships && activeMemberships.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Maintenance Request')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ NEW: no active rooms (backend will 400 anyway)
    if (activeRoomOptions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('New Maintenance Request')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_outlined,
                    size: 64, color: AppTheme.warningColor),
                const SizedBox(height: 16),
                Text('No Active Units',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'You must have an active unit lease to create a maintenance request.',
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
      appBar: AppBar(title: const Text('New Maintenance Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✅ Room selector only if multiple active rooms
            if (activeRoomOptions.length > 1) ...[
              Text(
                'Which unit is this for?',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedRoomId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                  hintText: 'Select unit',
                ),
                items: activeRoomOptions.map((o) {
                  return DropdownMenuItem(
                    value: o.roomId,
                    child: Text(o.label),
                  );
                }).toList(),
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _selectedRoomId = value),
                validator: (value) {
                  if (activeRoomOptions.length > 1 && value == null) {
                    return 'Please select a unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // ✅ Show selected info if only one active room
            if (activeRoomOptions.length == 1) ...[
              Card(
                color: AppTheme.tenantColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.apartment, color: AppTheme.tenantColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Reporting for:',
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                            Text(
                              activeRoomOptions.first.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
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
                          if (value != MaintenanceCategory.other) {
                            _customCategoryController.clear();
                          }
                        });
                      }
                    },
              validator: (value) =>
                  value == null ? 'Please select a category' : null,
            ),

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
                if (value == null || value.trim().isEmpty) return 'Please enter a title';
                if (value.trim().length < 5) return 'Title must be at least 5 characters';
                if (value.trim().length > 100) return 'Title must not exceed 100 characters';
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
                if (value == null || value.trim().isEmpty) return 'Please enter a description';
                if (value.trim().length < 10) return 'Description must be at least 10 characters';
                if (value.trim().length > 1000) return 'Description must not exceed 1000 characters';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Image Upload (Optional)
            Text(
              'Photos (Optional, up to $_maxImages)',
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
                  if (_selectedImages.isEmpty) ...[
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 48, color: AppTheme.textHint),
                    const SizedBox(height: 8),
                    Text('Add photos of the issue',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isSubmitting ? null : _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Choose Photos'),
                    ),
                  ] else ...[
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length +
                            (_selectedImages.length < _maxImages ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            // "Add more" button
                            return GestureDetector(
                              onTap: _isSubmitting ? null : _pickImages,
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: AppTheme.tenantColor, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined,
                                        color: AppTheme.tenantColor),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedImages.length}/$_maxImages',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              color: AppTheme.tenantColor),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final image = _selectedImages[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(image.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: _isSubmitting
                                      ? null
                                      : () => setState(
                                          () => _selectedImages.removeAt(index)),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: const Icon(Icons.close,
                                        color: Colors.white, size: 16),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Submit Request'),
              ),
            ),

            const SizedBox(height: 16),

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

class _RoomOption {
  final String roomId;
  final String label;
  _RoomOption({required this.roomId, required this.label});
}