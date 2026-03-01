import 'package:apartment_app/features/auth/presentation/screens/home/home_screen.dart';
import 'package:apartment_app/features/auth/presentation/screens/home/profile_screen.dart';
import 'package:apartment_app/features/auth/presentation/screens/role_selection_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/landlord_main_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/space_maintenance_screen.dart'; // 🆕 ADD
import 'package:apartment_app/features/landlord/presentation/screens/landlord_maintenance_details_screen.dart'; // 🆕 ADD
import 'package:apartment_app/features/tenant/presentation/screens/create_maintenance_screen.dart';
import 'package:apartment_app/features/tenant/presentation/screens/maintenance_details_screen.dart';
import 'package:apartment_app/features/tenant/presentation/screens/tenant_main_screen.dart';
import 'package:apartment_app/features/tenant/presentation/screens/join_space_screen.dart';
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
  // IMPORTANT: Do NOT use ref.watch(authProvider) here.
  // Watching causes the entire GoRouter to be recreated on every auth state
  // change (isLoading, clearError, etc.), resetting the navigation stack and
  // unmounting active screens mid-async-operation.
  // Auth state is read inside the redirect callback via ProviderScope instead.

  return GoRouter(
    initialLocation: '/auth/login',
    redirect: (context, state) {
      final authState =
          ProviderScope.containerOf(context, listen: false).read(authProvider);
      final isAuthenticated = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final isLoading = authState.isLoading;
      final isNewUser = authState.isNewUser;
      final currentPath = state.matchedLocation;
      final userRole = authState.user?.role;

      print('🧭 Router redirect check:');
      print('   Path: $currentPath');
      print('   Initialized: $isInitialized');
      print('   Authenticated: $isAuthenticated');
      print('   Role: $userRole');
      print('   Loading: $isLoading');
      print('   IsNewUser: $isNewUser');

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

      // New Google user needs to select their role before entering the app
      if (isAuthenticated && isNewUser && currentPath != '/role-selection') {
        print('   → Redirecting to /role-selection (new Google user)');
        return '/role-selection';
      }

      // Helper to redirect to the correct dashboard
      dashboardPath() {
        if (userRole == 'LANDLORD') return '/landlord';
        if (userRole == 'TENANT') return '/tenant';
        return '/home';
      }

      // If role selection is done, leave /role-selection
      if (currentPath == '/role-selection' && (!isAuthenticated || !isNewUser)) {
        print('   → Leaving /role-selection (role set)');
        return dashboardPath();
      }

      // After initialized, redirect from splash based on role
      if (currentPath == '/') {
        if (isAuthenticated) {
          print('   → Redirecting from splash to dashboard');
          return dashboardPath();
        } else {
          print('   → Redirecting to login (not authenticated)');
          return '/auth/login';
        }
      }

      // If authenticated and on auth pages, redirect to dashboard
      if (isAuthenticated && currentPath.startsWith('/auth')) {
        print('   → Redirecting to dashboard (already authenticated)');
        return dashboardPath();
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
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => LoginScreen(key: _loginKey),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => RegisterScreen(key: _registerKey),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      
      // ===== LANDLORD ROUTES =====
      GoRoute(
        path: '/landlord',
        builder: (context, state) => const LandlordMainScreen(),
      ),
      // 🆕 NEW: Landlord Maintenance Routes
      GoRoute(
        path: '/landlord/space/:spaceId/maintenance',
        builder: (context, state) {
          final spaceId = state.pathParameters['spaceId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final spaceName = extra?['spaceName'] as String?;
          
          return SpaceMaintenanceScreen(
            spaceId: spaceId,
            spaceName: spaceName ?? 'Space',
          );
        },
      ),
      GoRoute(
        path: '/landlord/space/:spaceId/maintenance/:requestId',
        builder: (context, state) {
          final spaceId = state.pathParameters['spaceId']!;
          final requestId = state.pathParameters['requestId']!;
          final extra = state.extra as Map<String, dynamic>?;
          final spaceName = extra?['spaceName'] as String?;
          
          return LandlordMaintenanceDetailsScreen(
            spaceId: spaceId,
            requestId: requestId,
            spaceName: spaceName,
          );
        },
      ),

GoRoute(
  path: '/landlord/maintenance/:spaceId/:requestId',
  builder: (context, state) {
    final spaceId = state.pathParameters['spaceId']!;
    final requestId = state.pathParameters['requestId']!;
    final extra = state.extra as Map<String, dynamic>?;
    final spaceName = extra?['spaceName'] as String?;
    
    return LandlordMaintenanceDetailsScreen(
      spaceId: spaceId,
      requestId: requestId,
      spaceName: spaceName,
    );
  },
),
      
      // ===== TENANT ROUTES =====
      GoRoute(
        path: '/tenant',
        builder: (context, state) => const TenantMainScreen(),
      ),
      GoRoute(
        path: '/tenant/join-space',
        builder: (context, state) => const JoinSpaceScreen(),
      ),
      GoRoute(
        path: '/tenant/maintenance/create',
        builder: (context, state) => const CreateMaintenanceScreen(),
      ),
      GoRoute(
        path: '/tenant/maintenance/details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return MaintenanceDetailsScreen(requestId: id);
        },
      ),
    ],
  );
});

// Helper class to make router reactive to provider changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(this.ref) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Notify on auth/init changes or when isNewUser is cleared (role selected)
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isInitialized != next.isInitialized ||
          previous?.isNewUser != next.isNewUser) {
        notifyListeners();
      }
    });
  }

  final Ref ref;
}