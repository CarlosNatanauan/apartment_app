import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/api/api_endpoints.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import 'package:apartment_app/core/api/api_response.dart';
import '../models/user_model.dart';
import '../models/auth_response.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorage _storage;

  AuthRepository(this._apiClient, this._storage);

  // Login
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.login,
        data: {
          'email': email,
          'password': password,
        },
        fromJson: (data) => LoginResponse.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Login failed');
      }

      final loginResponse = response.data!;

      // Save token
      await _storage.saveToken(loginResponse.accessToken);

      // Get user details from /auth/me
      final user = await getCurrentUser();
      
      // Save user data
      await _storage.saveUser(user);

      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Register
Future<User> register({
  required String firstName,   // 🆕 NEW
  required String lastName,    // 🆕 NEW
  required String email,
  required String password,
  required String role,
}) async {
  try {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      data: {
        'firstName': firstName,   // 🆕 NEW
        'lastName': lastName,     // 🆕 NEW
        'email': email,
        'password': password,
        'role': role,
      },
        fromJson: (data) => RegisterResponse.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Registration failed');
      }

      final registerResponse = response.data!;

      // Save token
      await _storage.saveToken(registerResponse.accessToken);

      // Get user details from /auth/me
      final user = await getCurrentUser();
      
      // Save user data
      await _storage.saveUser(user);

      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Get current user from API
  Future<User> getCurrentUser() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.me,
        fromJson: (data) => User.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Failed to get user');
      }

      return response.data!;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  // ✅ NEW: Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to change password');
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to change password: ${e.toString()}');
    }
  }

  // ✅ UPDATED: Logout - now calls backend
  Future<void> logout() async {
    try {
      // Call backend logout endpoint (for audit trail)
      await _apiClient.post(
        '/auth/logout',
        fromJson: (data) => data,
      );
    } catch (e) {
      // Even if backend call fails, still clear local storage
      print('⚠️ Backend logout failed: $e');
    } finally {
      // Always clear local storage
      await _storage.clearAll();
    }
  }

  // Google Sign-In — returns user + isNewUser flag
  Future<({User user, bool isNewUser})> googleSignIn({
    required String idToken,
    String? role,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.googleAuth,
        data: {
          'idToken': idToken,
          if (role != null) 'role': role,
        },
        fromJson: (data) => LoginResponse.fromJson(data),
      );

      if (!response.ok || response.data == null) {
        throw Exception('Google sign-in failed');
      }

      final loginResponse = response.data!;

      // Save token
      await _storage.saveToken(loginResponse.accessToken);

      // Get user details from /auth/me
      final user = await getCurrentUser();

      // Save user data
      await _storage.saveUser(user);

      return (user: user, isNewUser: loginResponse.isNewUser);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Google sign-in failed: ${e.toString()}');
    }
  }

  // Update role (used after Google sign-in for new users)
  Future<User> updateRole(String role) async {
    try {
      await _apiClient.patch(
        ApiEndpoints.updateRole,
        data: {'role': role},
        fromJson: (data) => data,
      );

      // Fetch updated user and cache it
      final user = await getCurrentUser();
      await _storage.saveUser(user);
      return user;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to update role: ${e.toString()}');
    }
  }

  // Delete account
  Future<void> deleteAccount({String? password}) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteAccount,
        data: password != null ? {'password': password} : null,
        fromJson: (data) => data,
      );

      if (!response.ok) {
        throw Exception('Failed to delete account');
      }

      // Clear local storage after successful deletion
      await _storage.clearAll();
    } on ApiException {
      rethrow;
    } catch (e) {
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storage.hasToken();
  }

  // Get cached user
  Future<User?> getCachedUser() async {
    return await _storage.getUser();
  }

  // Save user to cache
  Future<void> saveCachedUser(User user) async {
    await _storage.saveUser(user);
  }
}