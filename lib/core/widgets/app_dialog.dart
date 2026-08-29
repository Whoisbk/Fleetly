import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'primary_button.dart';

abstract final class AppDialog {
  static Future<void> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'OK',
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle(color: AppColors.textOnDark)),
              const SizedBox(height: 12),
              Text(
                message,
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: confirmLabel,
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
