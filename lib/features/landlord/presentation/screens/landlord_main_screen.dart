import 'package:apartment_app/features/landlord/presentation/providers/spaces_provider.dart';
import 'package:apartment_app/features/landlord/presentation/screens/all_spaces_maintenance_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/landlord_dashboard.dart';
import 'package:apartment_app/features/landlord/presentation/screens/spaces_list_screen.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LandlordMainScreen extends ConsumerStatefulWidget {
  const LandlordMainScreen({super.key});

  @override
  ConsumerState<LandlordMainScreen> createState() => _LandlordMainScreenState();
}

class _LandlordMainScreenState extends ConsumerState<LandlordMainScreen> {
  int _selectedIndex = 0;
  bool _isInitializing = true;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      LandlordDashboard(
        onSwitchToSpaces: () => setState(() => _selectedIndex = 1),
      ),
      const SpacesListScreen(),
      const AllSpacesMaintenanceScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      await ref.read(spacesProvider.notifier).loadSpaces();
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const _AppLoadingScreen(
        themeColor: AppTheme.landlordColor,
        icon: Icons.business,
        message: 'Getting your spaces ready...',
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppTheme.landlordColor,
        unselectedItemColor: AppTheme.textHint,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Spaces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_circle_outlined),
            activeIcon: Icon(Icons.build_circle),
            label: 'Maintenance',
          ),
        ],
      ),
    );
  }
}

class _AppLoadingScreen extends StatelessWidget {
  final Color themeColor;
  final IconData icon;
  final String message;

  const _AppLoadingScreen({
    required this.themeColor,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 56, color: themeColor),
              ),
              const SizedBox(height: 32),
              const Text(
                'SpaceNest',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: themeColor,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
