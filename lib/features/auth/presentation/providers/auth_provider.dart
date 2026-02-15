import 'package:apartment_app/core/api/api_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apartment_app/core/api/api_client.dart';
import 'package:apartment_app/core/storage/secure_storage.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';

// Auth state class
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  // Computed property
  bool get isAuthenticated => user != null && isInitialized;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  @override
  String toString() => 'AuthState(user: $user, isLoading: $isLoading, isAuthenticated: $isAuthenticated, isInitialized: $isInitialized)';
}

// Auth notifier using Notifier (flutter_riverpod 3.x)
class AuthNotifier extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    // Initialize repository
    _repository = ref.read(authRepositoryProvider);
    
    // Start initialization
    _initializeAuth();
    
    // Return initial state
    return AuthState();
  }

  // Initialize auth state on app start
  Future<void> _initializeAuth() async {
    try {
      print('🔄 Initializing auth...');
      
      final isLoggedIn = await _repository.isLoggedIn();
      
      if (isLoggedIn) {
        final user = await _repository.getCachedUser();
        
        if (user != null) {
          print('✅ User found in cache: $user');
          state = state.copyWith(
            user: user,
            isInitialized: true,
          );
        } else {
          // Token exists but no cached user, try to fetch
          try {
            final freshUser = await _repository.getCurrentUser();
            print('✅ User fetched from API: $freshUser');
            await _repository.saveCachedUser(freshUser);
            state = state.copyWith(
              user: freshUser,
              isInitialized: true,
            );
          } catch (e) {
            print('❌ Failed to fetch user, clearing auth');
            await _repository.logout();
            state = state.copyWith(
              isInitialized: true,
              clearUser: true,
            );
          }
        }
      } else {
        print('ℹ️ No token found');
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      print('❌ Auth initialization error: $e');
      state = state.copyWith(
        isInitialized: true,
        clearUser: true,
      );
    }
  }

  // Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    
    try {
      print('🔐 Attempting login for: $email');
      
      final user = await _repository.login(
        email: email,
        password: password,
      );
      
      print('✅ Login successful: $user');
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        isInitialized: true,
      );
    } on ApiException catch (e) {
      // Handle ApiException specifically
      print('❌ Login failed (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      // Handle other exceptions
      print('❌ Login failed (Exception): $e');
      
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // Register
Future<void> register(
  String firstName,    // 🆕 NEW
  String lastName,     // 🆕 NEW
  String email,
  String password,
  String role,
) async {
  state = state.copyWith(isLoading: true, clearError: true);
  
  try {
    print('📝 Attempting registration for: $email as $role');
    
    final user = await _repository.register(
      firstName: firstName,   // 🆕 NEW
      lastName: lastName,     // 🆕 NEW
      email: email,
      password: password,
      role: role,
    );
      
      print('✅ Registration successful: $user');
      
      state = state.copyWith(
        user: user,
        isLoading: false,
        isInitialized: true,
      );
    } on ApiException catch (e) {
      // Handle ApiException specifically
      print('❌ Registration failed (ApiException): ${e.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      // Handle other exceptions
      print('❌ Registration failed (Exception): $e');
      
      state = state.copyWith(
        isLoading: false,
        error: _extractErrorMessage(e),
      );
      rethrow;
    }
  }

  // ✅ NEW: Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      print('🔒 Attempting to change password');
      
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      
      print('✅ Password changed successfully');
    } on ApiException catch (e) {
      print('❌ Change password failed (ApiException): ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Change password failed (Exception): $e');
      throw Exception(_extractErrorMessage(e));
    }
  }

  // Logout
  Future<void> logout() async {
    print('👋 Logging out');
    await _repository.logout();
    state = AuthState(isInitialized: true);
  }

  // Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Extract user-friendly error message
  String _extractErrorMessage(dynamic error) {
    final errorStr = error.toString();
    
    // Remove common prefixes
    if (errorStr.startsWith('Exception: ')) {
      return errorStr.substring(11);
    }
    
    if (errorStr.startsWith('ApiException: ')) {
      return errorStr.substring(14);
    }
    
    // Default fallback
    return 'An error occurred. Please try again';
  }
}

// Providers
final secureStorageProvider = Provider((ref) => SecureStorage());

final apiClientProvider = Provider((ref) {
  final storage = ref.read(secureStorageProvider);
  return ApiClient(storage);
});

final authRepositoryProvider = Provider((ref) {
  final apiClient = ref.read(apiClientProvider);
  final storage = ref.read(secureStorageProvider);
  return AuthRepository(apiClient, storage);
});

// Use NotifierProvider instead of StateNotifierProvider
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});