import 'package:apartment_app/features/tenant/presentation/provider/tenant_memberships_provider.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_notices_provider.dart';
import 'package:apartment_app/features/tenant/presentation/provider/tenant_payments_provider.dart';
import 'package:apartment_app/features/tenant/presentation/screens/my_maintenance_screen.dart';
import 'package:apartment_app/features/tenant/presentation/screens/my_memberships_screen.dart';
import 'package:apartment_app/features/tenant/presentation/screens/tenant_dashboard.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TenantMainScreen extends ConsumerStatefulWidget {
  const TenantMainScreen({super.key});

  @override
  ConsumerState<TenantMainScreen> createState() => _TenantMainScreenState();
}

class _TenantMainScreenState extends ConsumerState<TenantMainScreen> {
  int _selectedIndex = 0;
  bool _isInitializing = true;

  final List<Widget> _screens = const [
    TenantDashboard(),
    MyMembershipsScreen(),
    MyMaintenanceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    try {
      await ref.read(tenantMembershipsProvider.notifier).loadMemberships();
      await Future.wait([
        ref.read(tenantNoticesProvider.notifier).loadAllNotices(),
        ref.read(tenantPaymentsProvider.notifier).loadPayments(),
      ]);
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const _AppLoadingScreen(
        themeColor: AppTheme.tenantColor,
        icon: Icons.apartment,
        message: 'Loading your dashboard...',
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
        selectedItemColor: AppTheme.tenantColor,
        unselectedItemColor: AppTheme.textHint,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment_outlined),
            activeIcon: Icon(Icons.apartment),
            label: 'My Spaces',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
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
