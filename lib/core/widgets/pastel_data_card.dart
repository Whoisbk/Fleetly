import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';
import '../utils/currency_formatter.dart';

class PastelDataCard extends StatelessWidget {
  const PastelDataCard({
    super.key,
    required this.title,
    required this.amount,
    required this.color,
    this.onTap,
  });

  final String title;
  final double amount;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.label()),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount),
              style: AppTextStyles.sectionTitle(),
            ),
          ],
        ),
      ),
    );
  }
}
