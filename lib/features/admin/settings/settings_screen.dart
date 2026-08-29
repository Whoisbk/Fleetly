import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/theme_toggle_tile.dart';
import '../../../services/auth_service.dart';
import '../widgets/admin_page_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        children: [
          const AdminPageHeader(
            title: 'Settings',
            subtitle: 'Account & app',
          ),
          const SizedBox(height: 24),
          if (user != null) ...[
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.lavender,
                    child: Text(user.avatarLetter, style: AppTextStyles.metric().copyWith(fontSize: 32)),
                  ),
                  const SizedBox(height: 12),
                  Text(user.displayName, style: AppTextStyles.sectionTitle()),
                  Text(user.email, style: AppTextStyles.body(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text('ADMIN', style: AppTextStyles.label()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
          _SettingsTile(
            icon: Icons.person_outline,
            label: 'Edit Profile',
            subtitle: 'Name and phone number',
            onTap: () => context.push(AppRouter.adminEditProfile),
          ),
          _SettingsTile(
            icon: Icons.lock_outline,
            label: 'Change Password',
            onTap: () => context.push(AppRouter.adminChangePassword),
          ),
          const SizedBox(height: 16),
          const ThemeToggleTile(),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'App Version',
            subtitle: '1.0.0',
          ),
          _SettingsTile(
            icon: Icons.cloud_outlined,
            label: 'Backend',
            subtitle: AppConstants.isSupabaseConfigured ? 'Supabase connected' : 'Demo mode',
          ),
          const SizedBox(height: 16),
          _SettingsTile(
            icon: Icons.logout,
            label: 'Sign Out',
            isDestructive: true,
            onTap: () => context.read<AuthService>().signOut(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppColors.error : AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.body().copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? AppColors.error : null,
                    ),
                  ),
                  if (subtitle != null)
                    Text(subtitle!, style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13)),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
