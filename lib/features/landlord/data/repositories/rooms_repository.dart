import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import '../models/room_model.dart';

class RoomsRepository {
  final ApiClient _apiClient;

  RoomsRepository(this._apiClient);

  // Get all rooms in a space
  Future<List<Room>> getRooms(String spaceId) async {
    try {
      final response = await _apiClient.get(
        '/spaces/$spaceId/rooms',
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => Room.fromJson(json)).toList();
          }
          return <Room>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load rooms');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load rooms: ${e.toString()}');
    }
  }

  // Create a single room
  Future<Room> createRoom(String spaceId, String roomNumber) async {
    try {
      final response = await _apiClient.post(
        '/spaces/$spaceId/rooms',
        data: {'roomNumber': roomNumber},
        fromJson: (data) => Room.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to create room');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create room: ${e.toString()}');
    }
  }

  // Create multiple rooms (bulk)
  Future<List<Room>> createRooms(String spaceId, List<String> roomNumbers) async {
    try {
      // ✅ FIX: Send as flat array of strings, not array of objects
      final response = await _apiClient.post(
        '/spaces/$spaceId/rooms',
        data: {'roomNumbers': roomNumbers},  // ✅ Changed from 'rooms' to 'roomNumbers'
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => Room.fromJson(json)).toList();
          }
          return <Room>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to create rooms');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create rooms: ${e.toString()}');
    }
  }

  // Update room number
  Future<Room> updateRoomNumber(String spaceId, String roomId, String newRoomNumber) async {
    try {
      final response = await _apiClient.patch(
        '/spaces/$spaceId/rooms/$roomId',
        data: {'roomNumber': newRoomNumber},
        fromJson: (data) => Room.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to update room');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update room: ${e.toString()}');
    }
  }

  // Delete room
  Future<void> deleteRoom(String spaceId, String roomId) async {
    try {
      final response = await _apiClient.delete(
        '/spaces/$spaceId/rooms/$roomId',
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to delete room');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete room: ${e.toString()}');
    }
  }
}