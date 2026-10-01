import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../widgets/driver_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/hero_stat_card.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class DailyLogScreen extends StatefulWidget {
  const DailyLogScreen({super.key});

  @override
  State<DailyLogScreen> createState() => _DailyLogScreenState();
}

class _DailyLogScreenState extends State<DailyLogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      context.read<FleetDataService>().loadDriverDashboard(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final today = fleet.todayDriverDay;
    final vehicle = fleet.assignedVehicle;
    final expenses = fleet.todayExpenses;
    final dateLabel = DateFormat('d MMMM yyyy').format(DateTime.now());

    final nothingLoaded = today == null && fleet.recentDriverDays.isEmpty;

    if (fleet.driverLoading && nothingLoaded) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (fleet.error != null && nothingLoaded) {
      return SafeArea(
        child: LoadErrorView(
          title: 'Daily log unavailable',
          message: fleet.error!,
          onRetry: _refresh,
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DriverPageHeader(
                title: 'Daily Log',
                subtitle: dateLabel,
              ),
              const SizedBox(height: 24),
              if (fleet.error != null) ...[
                LoadErrorView(
                  title: 'Couldn\'t refresh',
                  message: fleet.error!,
                  onRetry: _refresh,
                  compact: true,
                ),
                const SizedBox(height: 16),
              ],
              if (today == null || today.status != DriverDayStatus.active) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.skyBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, size: 48),
                      const SizedBox(height: 12),
                      Text('No active day', style: AppTextStyles.sectionTitle()),
                      const SizedBox(height: 8),
                      Text(
                        'Check in to start recording your day',
                        style: AppTextStyles.body(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Check In',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => context.push(AppRouter.driverCheckIn),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vehicle', style: AppTextStyles.label()),
                      if (vehicle != null) ...[
                        Text(vehicle.displayName, style: AppTextStyles.sectionTitle()),
                        Text(vehicle.registrationNumber, style: AppTextStyles.body(color: AppColors.textSecondary)),
                      ] else
                        Text('Not assigned', style: AppTextStyles.sectionTitle(color: AppColors.textSecondary)),
                      if (today.startingOdometer != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Starting KM: ${today.startingOdometer}',
                          style: AppTextStyles.body(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                HeroStatCard(
                  label: "Today's Net",
                  value: CurrencyFormatter.format(today.net),
                  subtitle: 'Earnings ${CurrencyFormatter.format(today.totalEarnings)}',
                  accentColor: AppColors.lavender,
                ),
                const SizedBox(height: 24),
                Text('SUMMARY', style: AppTextStyles.label()),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      SummaryRow(label: 'Earnings', amount: today.totalEarnings),
                      SummaryRow(label: 'Fuel', amount: today.fuelTotal),
                      SummaryRow(label: 'Other Expenses', amount: today.expenseTotal),
                      const Divider(height: 24),
                      SummaryRow(label: 'Net', amount: today.net, isNet: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ENTRIES', style: AppTextStyles.label()),
                    TextButton(
                      onPressed: () => context.push(AppRouter.driverEarnings),
                      child: const Text('Add +'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (expenses.isEmpty)
                  Text(
                    'No entries yet — add earnings or expenses',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  )
                else
                  ...expenses.map((e) => _ExpenseTile(expense: e)),
                if (today.notes != null) ...[
                  const SizedBox(height: 20),
                  Text('NOTES', style: AppTextStyles.label()),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.peach.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(today.notes!, style: AppTextStyles.body()),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'End Day',
                  icon: Icons.nightlight_round,
                  onPressed: () => context.push(AppRouter.driverEndDay),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense});

  final Expense expense;

  Color get _color => switch (expense.type) {
        ExpenseType.fuel => AppColors.mint,
        ExpenseType.maintenance => AppColors.peach,
        ExpenseType.repair => AppColors.peach,
        ExpenseType.other => AppColors.skyBlue,
      };

  String get _label => switch (expense.type) {
        ExpenseType.fuel => 'Fuel',
        ExpenseType.maintenance => 'Maintenance',
        ExpenseType.repair => 'Repair',
        ExpenseType.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_label, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
                if (expense.description != null)
                  Text(
                    expense.description!,
                    style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13),
                  ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.format(expense.amount),
            style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
