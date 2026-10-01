import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

/// Card-style load failure that matches the rest of the app.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.compact = false,
    this.actionLabel = 'Try again',
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final bool compact;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.peach,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_outlined, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(actionLabel)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: BoxDecoration(
              color: AppColors.peach,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_off_outlined, size: 28),
                ),
                const SizedBox(height: 16),
                Text(title, style: AppTextStyles.sectionTitle(), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: actionLabel,
            icon: Icons.refresh,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
