import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/fleet_data_service.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Auth first, then Supabase (DB + Storage) with Firebase JWT
  await FirebaseService.initialize();
  await SupabaseService.initialize();

  final authService = AuthService();
  await authService.initialize();

  final fleetDataService = FleetDataService();

  runApp(FleetlyApp(
    authService: authService,
    fleetDataService: fleetDataService,
  ));
}

class FleetlyApp extends StatelessWidget {
  const FleetlyApp({
    super.key,
    required this.authService,
    required this.fleetDataService,
  });

  final AuthService authService;
  final FleetDataService fleetDataService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: fleetDataService),
      ],
      child: MaterialApp.router(
        title: 'Fleetly',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        routerConfig: AppRouter.create(authService),
      ),
    );
  }
}
