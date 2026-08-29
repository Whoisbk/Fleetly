import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/floating_bottom_nav.dart';
import '../../../services/fleet_data_service.dart';
import '../dashboard/admin_dashboard_screen.dart';
import '../drivers/drivers_list_screen.dart';
import '../fleet/fleet_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../widgets/admin_drawer.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _navIndex;

  static const _pages = [
    AdminDashboardScreen(),
    DriversListScreen(),
    FleetScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fleet = context.read<FleetDataService>();
      fleet.loadAdminDashboard();
      fleet.loadAllDrivers();
      fleet.loadAllVehicles();
      fleet.loadReports();
    });
  }

  void _selectTab(int index) => setState(() => _navIndex = index);

  @override
  Widget build(BuildContext context) {
    return AdminShellScope(
      onTabSelected: _selectTab,
      child: Scaffold(
        drawer: const AdminDrawer(),
        body: IndexedStack(
          index: _navIndex,
          children: _pages,
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _navIndex,
          onTap: _selectTab,
          items: const [
            BottomNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
            BottomNavItem(icon: Icons.people_outline, activeIcon: Icons.people),
            BottomNavItem(icon: Icons.local_taxi_outlined, activeIcon: Icons.local_taxi),
            BottomNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart),
            BottomNavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings),
          ],
        ),
      ),
    );
  }
}
