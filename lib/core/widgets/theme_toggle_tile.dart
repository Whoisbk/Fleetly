import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isDark ? Icons.dark_mode : Icons.light_mode_outlined,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dark Mode',
                  style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  isDark ? 'Dark theme enabled' : 'Light theme enabled',
                  style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            activeTrackColor: AppColors.accent,
            onChanged: (value) => context.read<ThemeService>().setDarkMode(value),
          ),
        ],
      ),
    );
  }
}
