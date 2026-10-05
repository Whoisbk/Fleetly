import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../models/models.dart';
import '../../../services/distance_tracking_service.dart';
import '../../../services/fleet_data_service.dart';

class DayDetailScreen extends StatelessWidget {
  const DayDetailScreen({super.key, required this.dayId});

  final String dayId;

  @override
  Widget build(BuildContext context) {
    final day = FleetDataService.getDayById(dayId);
    if (day == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text('Day', style: AppTextStyles.sectionTitle()),
        ),
        body: LoadErrorView(
          title: 'Day unavailable',
          message:
              'This day is not on this device. Go back and open it from your history.',
          actionLabel: 'Go back',
          onRetry: () => context.pop(),
        ),
      );
    }

    final tracker = context.watch<DistanceTrackingService>();
    final expenses = FleetDataService.getExpensesForDay(dayId);
    final dateLabel = DateFormat('d MMMM yyyy').format(day.date);
    final trackedKm = tracker.kmForDay(day.id, day.distanceKm);
    final showTrackedDistance = trackedKm > 0 ||
        (day.startingOdometer == null && day.endingOdometer == null);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(dateLabel, style: AppTextStyles.sectionTitle()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                SummaryRow(label: 'Earnings', amount: day.totalEarnings),
                SummaryRow(label: 'Fuel', amount: day.fuelTotal),
                SummaryRow(label: 'Expenses', amount: day.expenseTotal),
                if (showTrackedDistance)
                  SummaryRow(
                    label: 'Distance',
                    amount: 0,
                    valueText: formatDistanceKm(trackedKm),
                  ),
                const Divider(height: 24),
                SummaryRow(label: 'Net', amount: day.net, isNet: true),
              ],
            ),
          ),
          if (day.startingOdometer != null || day.endingOdometer != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Odometer', style: AppTextStyles.label()),
                  if (day.startingOdometer != null)
                    Text('Start: ${day.startingOdometer} km',
                        style: AppTextStyles.body()),
                  if (day.endingOdometer != null)
                    Text('End: ${day.endingOdometer} km',
                        style: AppTextStyles.body()),
                ],
              ),
            ),
          ],
          if (expenses.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('ENTRIES', style: AppTextStyles.label()),
            const SizedBox(height: 12),
            ...expenses.map((e) => _ExpenseRow(expense: e)),
          ],
        ],
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final label = switch (expense.type) {
      ExpenseType.fuel => 'Fuel',
      ExpenseType.maintenance => 'Maintenance',
      ExpenseType.repair => 'Repair',
      ExpenseType.other => 'Other',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.body()
                      .copyWith(fontWeight: FontWeight.w600)),
              if (expense.description != null)
                Text(expense.description!,
                    style: AppTextStyles.body(color: AppColors.textSecondary)
                        .copyWith(fontSize: 13)),
            ],
          ),
          Text('R ${expense.amount.toStringAsFixed(0)}',
              style:
                  AppTextStyles.body().copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
