import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import '../models/space_model.dart';

class SpacesRepository {
  final ApiClient _apiClient;

  SpacesRepository(this._apiClient);

  // Get all spaces owned by current user
  Future<List<Space>> getMySpaces() async {
    try {
      final response = await _apiClient.get(
        '/spaces/my',
        fromJson: (data) {
          if (data is List) {
            return data.map((json) => Space.fromJson(json)).toList();
          }
          return <Space>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load spaces');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load spaces: ${e.toString()}');
    }
  }

  // Create a new space
  Future<Space> createSpace(String name) async {
    try {
      final response = await _apiClient.post(
        '/spaces',
        data: {'name': name},
        fromJson: (data) => Space.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to create space');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create space: ${e.toString()}');
    }
  }

  // Get space details by ID
  Future<Space> getSpaceDetails(String spaceId) async {
    try {
      final response = await _apiClient.get(
        '/spaces/$spaceId',
        fromJson: (data) => Space.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load space details');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load space details: ${e.toString()}');
    }
  }

  // Update space name
  Future<Space> updateSpaceName(String spaceId, String name) async {
    try {
      final response = await _apiClient.patch(
        '/spaces/$spaceId',
        data: {'name': name},
        fromJson: (data) => Space.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to update space');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update space: ${e.toString()}');
    }
  }

  // Delete space
  Future<void> deleteSpace(String spaceId) async {
    try {
      final response = await _apiClient.delete(
        '/spaces/$spaceId',
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to delete space');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete space: ${e.toString()}');
    }
  }
}