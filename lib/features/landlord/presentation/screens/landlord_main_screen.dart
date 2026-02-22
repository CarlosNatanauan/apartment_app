import 'package:apartment_app/features/landlord/presentation/screens/all_spaces_maintenance_screen.dart';
import 'package:apartment_app/features/landlord/presentation/screens/landlord_dashboard.dart';
import 'package:apartment_app/features/landlord/presentation/screens/spaces_list_screen.dart';
import 'package:apartment_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LandlordMainScreen extends StatefulWidget {
  const LandlordMainScreen({super.key});

  @override
  State<LandlordMainScreen> createState() => _LandlordMainScreenState();
}

class _LandlordMainScreenState extends State<LandlordMainScreen> {
  int _selectedIndex = 0;

final List<Widget> _screens = [
  const LandlordDashboard(),
  const SpacesListScreen(),
  const AllSpacesMaintenanceScreen(),
  
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
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

