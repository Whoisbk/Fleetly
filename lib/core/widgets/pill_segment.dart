import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import '../theme/app_text_styles.dart';

class PillSegment<T> extends StatelessWidget {
  const PillSegment({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
  });

  final List<T> options;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isSelected = option == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.textPrimary : AppColors.surface,
                  borderRadius: AppDecorations.pillRadius,
                  border: Border.all(
                    color: isSelected ? AppColors.textPrimary : AppColors.border,
                  ),
                ),
                child: Text(
                  labelBuilder(option),
                  style: AppTextStyles.body(
                    color: isSelected ? AppColors.textOnDark : AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
