import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/room_model.dart';
import '../../data/repositories/rooms_repository.dart';

// Rooms state
class RoomsState {
  final List<Room> rooms;
  final bool isLoading;
  final String? error;

  RoomsState({
    this.rooms = const [],
    this.isLoading = false,
    this.error,
  });

  RoomsState copyWith({
    List<Room>? rooms,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RoomsState(
      rooms: rooms ?? this.rooms,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// Rooms notifier
class RoomsNotifier extends Notifier<RoomsState> {
  late final RoomsRepository _repository;
  String? _currentSpaceId;

  @override
  RoomsState build() {
    final apiClient = ref.read(apiClientProvider);
    _repository = RoomsRepository(apiClient);
    
    return RoomsState();
  }

  // Load all rooms for a space
  Future<void> loadRooms(String spaceId) async {
    _currentSpaceId = spaceId;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      print('🏠 Loading rooms for space: $spaceId');
      
      final rooms = await _repository.getRooms(spaceId);
      
      print('✅ Loaded ${rooms.length} rooms');
      
      state = state.copyWith(
        rooms: rooms,
        isLoading: false,
      );
    } on ApiException catch (e) {
      print('❌ Failed to load rooms (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
    } catch (e) {
      print('❌ Failed to load rooms (Exception): $e');
      
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load rooms',
      );
    }
  }

  // Create single room
  Future<Room?> createRoom(String spaceId, String roomNumber) async {
    try {
      print('🏗️ Creating room: $roomNumber');
      
      final newRoom = await _repository.createRoom(spaceId, roomNumber);
      
      print('✅ Room created: ${newRoom.id}');
      
      // Add to list
      state = state.copyWith(
        rooms: [...state.rooms, newRoom],
      );
      
      return newRoom;
    } on ApiException catch (e) {
      print('❌ Failed to create room (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to create room (Exception): $e');
      
      state = state.copyWith(error: 'Failed to create room');
      rethrow;
    }
  }

  // Create multiple rooms (bulk)
  Future<List<Room>?> createRooms(String spaceId, List<String> roomNumbers) async {
    try {
      print('🏗️ Creating ${roomNumbers.length} rooms: ${roomNumbers.join(", ")}');
      
      final newRooms = await _repository.createRooms(spaceId, roomNumbers);
      
      print('✅ ${newRooms.length} rooms created');
      
      // Add all to list
      state = state.copyWith(
        rooms: [...state.rooms, ...newRooms],
      );
      
      return newRooms;
    } on ApiException catch (e) {
      print('❌ Failed to create rooms (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to create rooms (Exception): $e');
      
      state = state.copyWith(error: 'Failed to create rooms');
      rethrow;
    }
  }

  // Update room number
  Future<void> updateRoomNumber(String spaceId, String roomId, String newRoomNumber) async {
    try {
      print('✏️ Updating room $roomId: $newRoomNumber');
      
      final updatedRoom = await _repository.updateRoomNumber(spaceId, roomId, newRoomNumber);
      
      print('✅ Room updated');
      
      // Update in list
      final updatedRooms = state.rooms.map((room) {
        return room.id == roomId ? updatedRoom : room;
      }).toList();
      
      state = state.copyWith(rooms: updatedRooms);
    } on ApiException catch (e) {
      print('❌ Failed to update room (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to update room (Exception): $e');
      
      state = state.copyWith(error: 'Failed to update room');
      rethrow;
    }
  }

  // Delete room
  Future<void> deleteRoom(String spaceId, String roomId) async {
    try {
      print('🗑️ Deleting room: $roomId');
      
      await _repository.deleteRoom(spaceId, roomId);
      
      print('✅ Room deleted');
      
      // Remove from list
      final updatedRooms = state.rooms
          .where((room) => room.id != roomId)
          .toList();
      
      state = state.copyWith(rooms: updatedRooms);
    } on ApiException catch (e) {
      print('❌ Failed to delete room (ApiException): ${e.message}');
      
      state = state.copyWith(error: e.message);
      rethrow;
    } catch (e) {
      print('❌ Failed to delete room (Exception): $e');
      
      state = state.copyWith(error: 'Failed to delete room');
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

// Provider (reuse existing apiClientProvider and secureStorageProvider from spaces)
final roomsProvider = NotifierProvider<RoomsNotifier, RoomsState>(() {
  return RoomsNotifier();
});