import 'package:apartment_app/features/auth/presentation/screens/home/home_screen.dart';
import 'package:apartment_app/features/auth/presentation/screens/home/profile_screen.dart';
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
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/auth/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isInitialized = authState.isInitialized;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;
      final userRole = authState.user?.role;

      print('🧭 Router redirect check:');
      print('   Path: $currentPath');
      print('   Initialized: $isInitialized');
      print('   Authenticated: $isAuthenticated');
      print('   Role: $userRole');
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

      // After initialized, redirect from splash based on role
      if (isInitialized && currentPath == '/') {
        if (isAuthenticated) {
          if (userRole == 'LANDLORD') {
            print('   → Redirecting to /landlord (LANDLORD user)');
            return '/landlord';
          } else if (userRole == 'TENANT') {
            print('   → Redirecting to /tenant (TENANT user)');
            return '/tenant';
          } else {
            print('   → Redirecting to /home (unknown role)');
            return '/home';
          }
        } else {
          print('   → Redirecting to login (not authenticated)');
          return '/auth/login';
        }
      }

      // If authenticated and on auth pages, redirect based on role
      if (isAuthenticated && currentPath.startsWith('/auth')) {
        if (userRole == 'LANDLORD') {
          print('   → Redirecting to /landlord (already authenticated as LANDLORD)');
          return '/landlord';
        } else if (userRole == 'TENANT') {
          print('   → Redirecting to /tenant (already authenticated as TENANT)');
          return '/tenant';
        } else {
          print('   → Redirecting to /home (already authenticated, unknown role)');
          return '/home';
        }
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
      // Only notify if auth status changed (not loading state)
      if (previous?.isAuthenticated != next.isAuthenticated ||
          previous?.isInitialized != next.isInitialized) {
        notifyListeners();
      }
    });
  }

  final Ref ref;
}