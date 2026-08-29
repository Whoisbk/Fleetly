import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/admin/drivers/driver_detail_screen.dart';
import '../../features/admin/drivers/pending_approvals_screen.dart';
import '../../features/admin/fleet/vehicle_form_screen.dart';
import '../../features/admin/shell/admin_shell_screen.dart';
import '../../features/auth/forgot_password/forgot_password_screen.dart';
import '../../features/auth/login/login_screen.dart';
import '../../features/auth/signup/signup_screen.dart';
import '../../features/auth/status/account_status_screen.dart';
import '../../features/driver/check_in/check_in_screen.dart';
import '../../features/driver/check_in/end_day_screen.dart';
import '../../features/driver/documents/documents_screen.dart';
import '../../features/driver/documents/upload_document_screen.dart';
import '../../features/driver/earnings/add_earnings_screen.dart';
import '../../features/driver/expenses/add_expense_screen.dart';
import '../../features/driver/expenses/add_fuel_screen.dart';
import '../../features/driver/history/day_detail_screen.dart';
import '../../features/driver/history/driver_history_screen.dart';
import '../../features/driver/profile/change_password_screen.dart';
import '../../features/driver/profile/edit_profile_screen.dart';
import '../../features/driver/shell/driver_shell_screen.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';

class AppRouter {
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const pending = '/pending';
  static const rejected = '/rejected';
  static const suspended = '/suspended';
  static const driverHome = '/driver';
  static const driverCheckIn = '/driver/check-in';
  static const driverEndDay = '/driver/end-day';
  static const driverEarnings = '/driver/earnings';
  static const driverFuel = '/driver/fuel';
  static const driverAddExpense = '/driver/add-expense';
  static const driverHistory = '/driver/history';
  static const driverEditProfile = '/driver/profile/edit';
  static const driverChangePassword = '/driver/profile/password';
  static const driverDocuments = '/driver/documents';
  static const driverUploadDocument = '/driver/documents/upload';
  static const adminHome = '/admin';
  static const adminApprovals = '/admin/approvals';
  static const adminDrivers = '/admin/drivers';
  static const adminVehicles = '/admin/vehicles';
  static const adminAddVehicle = '/admin/vehicles/add';
  static const adminEditProfile = '/admin/profile/edit';
  static const adminChangePassword = '/admin/profile/password';

  static GoRouter create(AuthService authService) {
    return GoRouter(
      initialLocation: login,
      refreshListenable: authService,
      redirect: (context, state) {
        final user = authService.currentUser;
        final path = state.matchedLocation;
        final isAuthRoute =
            path == login || path == signup || path == forgotPassword;
        final isStatusRoute = path == pending || path == rejected || path == suspended;

        if (user == null) {
          return isAuthRoute ? null : login;
        }

        if (user.isAdmin) {
          if (isAuthRoute) return adminHome;
          return null;
        }

        switch (user.status) {
          case UserStatus.pending:
            return path == pending ? null : pending;
          case UserStatus.rejected:
            return path == rejected ? null : rejected;
          case UserStatus.suspended:
            return path == suspended ? null : suspended;
          case UserStatus.approved:
            if (isAuthRoute || isStatusRoute) return driverHome;
            return null;
        }
      },
      routes: [
        GoRoute(path: login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: signup, builder: (_, __) => const SignupScreen()),
        GoRoute(
          path: forgotPassword,
          builder: (_, state) => ForgotPasswordScreen(
            initialEmail: state.extra is String ? state.extra as String : null,
          ),
        ),
        GoRoute(
          path: pending,
          builder: (_, __) => const AccountStatusScreen(
            title: 'Application Pending',
            message: 'Your account is waiting for administrator approval. We\'ll notify you once reviewed.',
            statusLabel: 'PENDING',
            icon: Icons.hourglass_top_outlined,
          ),
        ),
        GoRoute(
          path: rejected,
          builder: (_, __) => const AccountStatusScreen(
            title: 'Application Rejected',
            message: 'Your application was not approved. Please contact the fleet administrator.',
            statusLabel: 'REJECTED',
            icon: Icons.cancel_outlined,
            isError: true,
          ),
        ),
        GoRoute(
          path: suspended,
          builder: (_, __) => const AccountStatusScreen(
            title: 'Account Suspended',
            message: 'Your account has been suspended. Please contact the fleet administrator.',
            statusLabel: 'SUSPENDED',
            icon: Icons.block_outlined,
            isError: true,
          ),
        ),
        GoRoute(path: driverHome, builder: (_, __) => const DriverShellScreen()),
        GoRoute(path: driverCheckIn, builder: (_, __) => const CheckInScreen()),
        GoRoute(path: driverEndDay, builder: (_, __) => const EndDayScreen()),
        GoRoute(path: driverEarnings, builder: (_, __) => const AddEarningsScreen()),
        GoRoute(path: driverFuel, builder: (_, __) => const AddFuelScreen()),
        GoRoute(path: driverAddExpense, builder: (_, __) => const AddExpenseScreen()),
        GoRoute(path: driverHistory, builder: (_, __) => const DriverHistoryScreen()),
        GoRoute(
          path: '$driverHistory/:dayId',
          builder: (_, state) => DayDetailScreen(dayId: state.pathParameters['dayId']!),
        ),
        GoRoute(path: driverEditProfile, builder: (_, __) => const EditProfileScreen()),
        GoRoute(path: driverChangePassword, builder: (_, __) => const ChangePasswordScreen()),
        GoRoute(path: driverDocuments, builder: (_, __) => const DocumentsScreen()),
        GoRoute(path: driverUploadDocument, builder: (_, __) => const UploadDocumentScreen()),
        GoRoute(path: adminHome, builder: (_, __) => const AdminShellScreen()),
        GoRoute(path: adminApprovals, builder: (_, __) => const PendingApprovalsScreen()),
        GoRoute(
          path: '$adminDrivers/:driverId',
          builder: (_, state) => DriverDetailScreen(driverId: state.pathParameters['driverId']!),
        ),
        GoRoute(path: adminAddVehicle, builder: (_, __) => const VehicleFormScreen()),
        GoRoute(
          path: '$adminVehicles/:vehicleId/edit',
          builder: (_, state) => VehicleFormScreen(vehicleId: state.pathParameters['vehicleId']),
        ),
        GoRoute(path: adminEditProfile, builder: (_, __) => const EditProfileScreen()),
        GoRoute(path: adminChangePassword, builder: (_, __) => const ChangePasswordScreen()),
      ],
    );
  }
}

extension RouterContext on BuildContext {
  AuthService get auth => read<AuthService>();
}
