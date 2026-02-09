import 'package:apartment_app/features/auth/presentation/screens/home/home_screen.dart';
import 'package:apartment_app/features/auth/presentation/screens/home/profile_screen.dart'; // ✅ NEW
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/providers/auth_provider.dart';

// ✅ Global keys to preserve widget state
final _loginKey = GlobalKey();
final _registerKey = GlobalKey();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;

      print('🧭 Router redirect check:');
      print('   Path: $currentPath');
      print('   Initialized: $isInitialized');
      print('   Authenticated: $isAuthenticated');
      print('   Loading: $isLoading');

      // Don't redirect if currently loading
      if (isLoading) {
        print('   → No redirect (loading in progress)');
        return null;
      }

      // Show splash only during initialization
      if (!isInitialized) {
        print('   → Redirecting to splash (initializing)');
        return '/';
      }

      // After initialized, redirect from splash based on auth status
      if (isInitialized && currentPath == '/') {
        if (isAuthenticated) {
          print('   → Redirecting to home (authenticated)');
          return '/home';
        } else {
          print('   → Redirecting to login (not authenticated)');
          return '/auth/login';
        }
      }

      // If authenticated and on auth pages, go to home
      if (isAuthenticated && currentPath.startsWith('/auth')) {
        print('   → Redirecting to home (already authenticated)');
        return '/home';
      }

      // If not authenticated and trying to access protected pages, go to login
      if (!isAuthenticated && 
          !currentPath.startsWith('/auth') && 
          currentPath != '/') {
        print('   → Redirecting to login (protected page)');
        return '/auth/login';
      }

      print('   → No redirect needed');
      return null;
    },
    refreshListenable: GoRouterRefreshStream(ref),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => LoginScreen(key: _loginKey),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => RegisterScreen(key: _registerKey),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      // ✅ NEW: Profile route
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});

// Helper class to make router reactive to provider changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this.ref) {
    ref.listen<AuthState>(
      authProvider,
      (previous, next) {
        // Only notify if auth status changed (not loading state)
        if (previous?.isAuthenticated != next.isAuthenticated ||
            previous?.isInitialized != next.isInitialized) {
          notifyListeners();
        }
      },
    );
  }

  final Ref ref;
}