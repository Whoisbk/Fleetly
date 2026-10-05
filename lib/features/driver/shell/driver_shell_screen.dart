import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/floating_bottom_nav.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/distance_tracking_service.dart';
import '../../../services/fleet_data_service.dart';
import '../dashboard/driver_dashboard_screen.dart';
import '../daily_log/daily_log_screen.dart';
import '../history/driver_history_screen.dart';
import '../profile/profile_screen.dart';
import '../quick_actions/quick_add_sheet.dart';
import '../widgets/driver_drawer.dart';

class DriverShellScreen extends StatefulWidget {
  const DriverShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<DriverShellScreen> createState() => _DriverShellScreenState();
}

class _DriverShellScreenState extends State<DriverShellScreen>
    with WidgetsBindingObserver {
  late int _navIndex;

  static const _pages = [
    DriverDashboardScreen(),
    DailyLogScreen(),
    DriverHistoryScreen(),
    ProfileScreen(),
  ];

  int get _pageIndex => switch (_navIndex) {
        0 => 0,
        1 => 1,
        3 => 2,
        4 => 3,
        _ => 0,
      };

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndTrack());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final fleet = context.read<FleetDataService>();
    if (fleet.isSubmitting) return;
    final today = fleet.todayDriverDay;
    if (today == null || today.status != DriverDayStatus.active) return;
    final tracker = context.read<DistanceTrackingService>();
    if (tracker.isTracking) return;
    tracker.start(driverDayId: today.id, serverKm: today.distanceKm);
  }

  Future<void> _loadAndTrack() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;
    await context.read<FleetDataService>().loadDriverDashboard(user.id);
    if (!mounted) return;
    final today = context.read<FleetDataService>().todayDriverDay;
    if (today != null && today.status == DriverDayStatus.active) {
      await context.read<DistanceTrackingService>().start(
            driverDayId: today.id,
            serverKm: today.distanceKm,
          );
    }
  }

  void _selectTab(int index) => setState(() => _navIndex = index);

  void _onNavTap(int index) {
    if (index == 2) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const QuickAddSheet(),
      );
      return;
    }
    setState(() => _navIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return DriverShellScope(
      onTabSelected: _selectTab,
      child: Scaffold(
        drawer: const DriverDrawer(),
        body: IndexedStack(
          index: _pageIndex,
          children: _pages,
        ),
        bottomNavigationBar: FloatingBottomNav(
          currentIndex: _navIndex,
          onTap: _onNavTap,
          items: const [
            BottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home),
            BottomNavItem(
                icon: Icons.edit_note_outlined, activeIcon: Icons.edit_note),
            BottomNavItem(
                icon: Icons.add_circle_outline, activeIcon: Icons.add_circle),
            BottomNavItem(icon: Icons.history, activeIcon: Icons.history),
            BottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person),
          ],
        ),
      ),
    );
  }
}
