import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/auth_service.dart';

class DriverShellScope extends InheritedWidget {
  const DriverShellScope({
    super.key,
    required this.onTabSelected,
    required super.child,
  });

  final void Function(int tabIndex) onTabSelected;

  static DriverShellScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DriverShellScope>();
  }

  @override
  bool updateShouldNotify(DriverShellScope oldWidget) => false;
}

class DriverDrawer extends StatelessWidget {
  const DriverDrawer({super.key});

  void _closeAndNavigate(BuildContext context, VoidCallback action) {
    Navigator.pop(context);
    action();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    final shell = DriverShellScope.of(context);

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.lavender,
                    child: Text(
                      user.avatarLetter,
                      style: AppTextStyles.sectionTitle(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName, style: AppTextStyles.sectionTitle()),
                        Text(
                          user.email,
                          style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerTile(
                    icon: Icons.home_outlined,
                    label: 'Home',
                    onTap: () => _closeAndNavigate(context, () => shell?.onTabSelected(0)),
                  ),
                  _DrawerTile(
                    icon: Icons.edit_note_outlined,
                    label: 'Daily Log',
                    onTap: () => _closeAndNavigate(context, () => shell?.onTabSelected(1)),
                  ),
                  _DrawerTile(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => _closeAndNavigate(context, () => shell?.onTabSelected(3)),
                  ),
                  _DrawerTile(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    onTap: () => _closeAndNavigate(context, () => shell?.onTabSelected(4)),
                  ),
                  _DrawerTile(
                    icon: Icons.description_outlined,
                    label: 'Documents',
                    onTap: () => _closeAndNavigate(
                      context,
                      () => context.push(AppRouter.driverDocuments),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppConstants.appName, style: AppTextStyles.label()),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.read<AuthService>().signOut();
                      },
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Sign Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22),
      ),
      title: Text(label, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
