import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.label,
    this.subtitle,
    this.isUploaded = false,
    this.isHighlighted = false,
    this.fileName,
    this.onTap,
  });

  final String label;
  final String? subtitle;
  final bool isUploaded;
  final bool isHighlighted;
  final String? fileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppColors.mint
              : isHighlighted
                  ? AppColors.lavender
                  : AppColors.skyBlue,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted ? AppColors.textPrimary : AppColors.border,
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isUploaded
                  ? Icons.check_circle_outline
                  : Icons.upload_file_outlined,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.body()
                          .copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    isUploaded
                        ? (fileName ?? 'Uploaded')
                        : (subtitle ?? 'Tap to upload'),
                    style: AppTextStyles.body(color: AppColors.textSecondary)
                        .copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              isUploaded ? Icons.visibility_outlined : Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
