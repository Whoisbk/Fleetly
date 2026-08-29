import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/models.dart';

class DriverStatusBadge extends StatelessWidget {
  const DriverStatusBadge({super.key, required this.status});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      UserStatus.approved => ('Approved', AppColors.mint),
      UserStatus.pending => ('Pending', AppColors.peach),
      UserStatus.rejected => ('Rejected', AppColors.error.withOpacity(0.15)),
      UserStatus.suspended => ('Suspended', AppColors.skyBlue),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: AppTextStyles.label()),
    );
  }
}
