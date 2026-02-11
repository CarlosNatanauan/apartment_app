import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/space_model.dart';
import '../../data/repositories/spaces_repository.dart';

// Spaces state
class SpacesState {
  final List<Space> spaces;
  final bool isLoading;
  final String? error;

  SpacesState({
    this.spaces = const [],
    this.isLoading = false,
    this.error,
  });

  SpacesState copyWith({
    List<Space>? spaces,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SpacesState(
      spaces: spaces ?? this.spaces,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Spaces notifier
class SpacesNotifier extends Notifier<SpacesState> {
  late final SpacesRepository _repository;

  @override
  SpacesState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = SpacesRepository(apiClient);
    
    // ✅ FIX: Don't auto-load here, it causes circular dependency
    // Load will be triggered by the screen
    
    return SpacesState();
  }

  // Load all spaces
  Future<void> loadSpaces() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      print('📦 Loading spaces...');
      
      final spaces = await _repository.getMySpaces();
      
      print('✅ Loaded ${spaces.length} spaces');
      
      state = state.copyWith(
        spaces: spaces,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load spaces (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load spaces (Exception): $e');
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load spaces',
      );
    }
  }

  // Create new space
  Future<Space?> createSpace(String name) async {
    try {
      print('🏗️ Creating space: $name');
      
      final newSpace = await _repository.createSpace(name);
      
      print('✅ Space created: ${newSpace.id}');
      
      // Add to list
      state = state.copyWith(
        spaces: [...state.spaces, newSpace],
      );
      
      return newSpace;
    } on ApiException catch (e) {
      print('❌ Failed to create space (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to create space (Exception): $e');
      
      state = state.copyWith(error: 'Failed to create space');
      rethrow;
    }
  }

  // Update space name
Future<void> updateSpaceName(String spaceId, String name) async {
  try {
    print('✏️ Updating space $spaceId: $name');
    
    final updatedSpace = await _repository.updateSpaceName(spaceId, name);
    
    print('✅ Space updated from API');
    print('   Updated space data: ${updatedSpace.toString()}');
    print('   ID: ${updatedSpace.id}');
    print('   Name: ${updatedSpace.name}');
    print('   JoinCode: ${updatedSpace.joinCode}');
    print('   OwnerId: ${updatedSpace.ownerId}');
    
    // Update in list
    print('📝 Updating local state...');
    final updatedSpaces = state.spaces.map((space) {
      if (space.id == spaceId) {
        print('   Found space to update: ${space.name} -> ${updatedSpace.name}');
        return updatedSpace;
      }
      return space;
    }).toList();
    
    print('✅ Local state updated, setting new state...');
    state = state.copyWith(spaces: updatedSpaces);
    print('✅ State set successfully');
    
  } on ApiException catch (e) {
    print('❌ Failed to update space (ApiException): ${e.message}');
    
    state = state.copyWith(error: e.message);
    rethrow;
  } catch (e, stackTrace) {
    print('❌ Failed to update space (Exception): $e');
    print('📍 Stack trace: $stackTrace');
    
    state = state.copyWith(error: 'Failed to update space');
    rethrow;
  }
}
  // Delete space
  Future<void> deleteSpace(String spaceId) async {
    try {
      print('🗑️ Deleting space: $spaceId');
      
      await _repository.deleteSpace(spaceId);
      
      print('✅ Space deleted');
      
      // Remove from list
      final updatedSpaces = state.spaces
          .where((space) => space.id != spaceId)
          .toList();
      
      state = state.copyWith(spaces: updatedSpaces);
    } on ApiException catch (e) {
      print('❌ Failed to delete space (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to delete space (Exception): $e');
      
      state = state.copyWith(error: 'Failed to delete space');
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider
final apiClientProvider = Provider((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage);
});

final secureStorageProvider = Provider((ref) => SecureStorage());

final spacesProvider = NotifierProvider<SpacesNotifier, SpacesState>(() {
  return SpacesNotifier();
});