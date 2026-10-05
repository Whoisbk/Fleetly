import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/distance_tracking_service.dart';
import 'services/firebase_service.dart';
import 'services/fleet_data_service.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Auth first, then Supabase (DB + Storage) with Firebase JWT
  await FirebaseService.initialize();
  await SupabaseService.initialize();

  final authService = AuthService();
  await authService.initialize();

  final fleetDataService = FleetDataService();
  final themeService = ThemeService();
  final distanceTrackingService = DistanceTrackingService();
  await themeService.initialize();

  runApp(FleetlyApp(
    authService: authService,
    fleetDataService: fleetDataService,
    themeService: themeService,
    distanceTrackingService: distanceTrackingService,
  ));
}

class FleetlyApp extends StatelessWidget {
  const FleetlyApp({
    super.key,
    required this.authService,
    required this.fleetDataService,
    required this.themeService,
    required this.distanceTrackingService,
  });

  final AuthService authService;
  final FleetDataService fleetDataService;
  final ThemeService themeService;
  final DistanceTrackingService distanceTrackingService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: fleetDataService),
        ChangeNotifierProvider.value(value: themeService),
        ChangeNotifierProvider.value(value: distanceTrackingService),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, _) {
          return MaterialApp.router(
            title: 'Fleetly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeService.themeMode,
            routerConfig: AppRouter.create(authService),
          );
        },
      ),
    );
  }
}
