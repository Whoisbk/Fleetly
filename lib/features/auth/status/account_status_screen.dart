import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';

class AccountStatusScreen extends StatelessWidget {
  const AccountStatusScreen({
    super.key,
    required this.title,
    required this.message,
    required this.statusLabel,
    required this.icon,
    this.isError = false,
  });

  final String title;
  final String message;
  final String statusLabel;
  final IconData icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final accent = isError ? AppColors.peach : AppColors.lavender;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 48, color: AppColors.textPrimary),
                    const SizedBox(height: 16),
                    Text(title, style: AppTextStyles.sectionTitle(), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      style: AppTextStyles.body(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Status: $statusLabel',
                        style: AppTextStyles.label(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Sign Out',
                onPressed: () => context.read<AuthService>().signOut(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
