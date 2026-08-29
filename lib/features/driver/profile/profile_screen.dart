import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../services/auth_service.dart';
import '../widgets/driver_page_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DriverPageHeader(title: 'Profile'),
            const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.lavender,
                      child: Text(
                        user.avatarLetter,
                        style: AppTextStyles.metric().copyWith(fontSize: 36),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.displayName, style: AppTextStyles.sectionTitle()),
                    Text(user.email, style: AppTextStyles.body(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _ProfileTile(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                subtitle: 'Name, phone, photo',
                onTap: () => context.push(AppRouter.driverEditProfile),
              ),
              _ProfileTile(
                icon: Icons.description_outlined,
                label: 'Documents',
                subtitle: 'ID & PDP',
                onTap: () => context.push(AppRouter.driverDocuments),
              ),
              _ProfileTile(
                icon: Icons.lock_outline,
                label: 'Change Password',
                onTap: () => context.push(AppRouter.driverChangePassword),
              ),
              const SizedBox(height: 24),
              _ProfileTile(
                icon: Icons.logout,
                label: 'Sign Out',
                isDestructive: true,
                onTap: () => context.read<AuthService>().signOut(),
              ),
            ],
          ),
        ),
      );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
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
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
