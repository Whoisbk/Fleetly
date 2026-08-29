import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/currency_formatter.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.amount,
    this.isTotal = false,
    this.isNet = false,
  });

  final String label;
  final double amount;
  final bool isTotal;
  final bool isNet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isTotal || isNet
                ? AppTextStyles.body().copyWith(fontWeight: FontWeight.w700)
                : AppTextStyles.body(color: AppColors.textSecondary),
          ),
          Text(
            CurrencyFormatter.format(amount),
            style: isTotal || isNet
                ? AppTextStyles.sectionTitle()
                : AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
