import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/currency_formatter.dart';
import '../utils/distance_formatter.dart';

class TimelineEntry extends StatelessWidget {
  const TimelineEntry({
    super.key,
    required this.date,
    required this.earnings,
    required this.fuel,
    required this.expenses,
    required this.isLast,
    this.distanceKm,
    this.color = AppColors.lavender,
  });

  final DateTime date;
  final double earnings;
  final double fuel;
  final double expenses;
  final bool isLast;
  final double? distanceKm;
  final Color color;

  double get net => earnings - fuel - expenses;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('d MMM').format(date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppColors.border),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(dateLabel, style: AppTextStyles.sectionTitle()),
                        Text(
                          'Net ${CurrencyFormatter.format(net)}',
                          style: AppTextStyles.body()
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _row('Earnings', earnings),
                    _row('Fuel', fuel),
                    _row('Expenses', expenses),
                    if (distanceKm != null && distanceKm! > 0)
                      _textRow('Distance', formatDistanceKm(distanceKm!)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.body(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.body()),
        ],
      ),
    );
  }

  Widget _row(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: AppTextStyles.body(color: AppColors.textSecondary)),
          Text(CurrencyFormatter.format(amount), style: AppTextStyles.body()),
        ],
      ),
    );
  }
}
