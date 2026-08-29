import 'package:flutter_test/flutter_test.dart';
import 'package:taxi_fleet_app/main.dart';
import 'package:taxi_fleet_app/services/auth_service.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    final authService = AuthService();
    await tester.pumpWidget(FleetlyApp(authService: authService));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
