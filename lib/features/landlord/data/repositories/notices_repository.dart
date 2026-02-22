import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_response.dart';
import '../models/notice_models.dart';

class NoticesRepository {
  final ApiClient _apiClient;

  NoticesRepository(this._apiClient);

  // Get all active notices for a space
  Future<List<SpaceNotice>> getNotices(String spaceId) async {
    try {
      print('📢 Loading notices for space: $spaceId');
      
      final response = await _apiClient.get(
        '/spaces/$spaceId/notices',
        fromJson: (data) {
          if (data is List) {
            return data
                .map((json) => SpaceNotice.fromJson(json as Map<String, dynamic>))
                .toList();
          }
          return <SpaceNotice>[];
        },
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to load notices');
      }

      print('✅ Loaded ${response.data!.length} notices');
      
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to load notices: ${e.toString()}');
    }
  }

  // Create a new notice
  Future<SpaceNotice> createNotice({
    required String spaceId,
    required String title,
    required String content,
    DateTime? expiresAt,
  }) async {
    try {
      print('📝 Creating notice for space: $spaceId');
      
      final Map<String, dynamic> requestData = {
        'title': title,
        'content': content,
      };
      
      if (expiresAt != null) {
        requestData['expiresAt'] = expiresAt.toIso8601String();
      }

      final response = await _apiClient.post(
        '/spaces/$spaceId/notices',
        data: requestData,
        fromJson: (data) => SpaceNotice.fromJson(data as Map<String, dynamic>),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to create notice');
      }

      print('✅ Notice created successfully');
      
      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to create notice: ${e.toString()}');
    }
  }

  // Delete a notice
  Future<void> deleteNotice({
    required String spaceId,
    required String noticeId,
  }) async {
    try {
      print('🗑️ Deleting notice: $noticeId');
      
      final response = await _apiClient.delete(
        '/spaces/$spaceId/notices/$noticeId',
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to delete notice');
      }

      print('✅ Notice deleted successfully');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete notice: ${e.toString()}');
    }
  }
}