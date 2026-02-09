import 'package:apartment_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/landlord_main_screen.dart';
import 'package:apartment_app/features/tenant/presentation/screens/tenant_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data')),
      );
    }

    // Route to role-specific main screen with bottom navigation
    if (user.isLandlord) {
      return const LandlordMainScreen();
    } else {
      return const TenantMainScreen();
    }
  }
}