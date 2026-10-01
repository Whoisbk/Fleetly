import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/hero_stat_card.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../core/widgets/pastel_data_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/timeline_entry.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';
import '../widgets/driver_drawer.dart';
import '../widgets/driver_page_header.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      context.read<FleetDataService>().loadDriverDashboard(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthService>().currentUser!;
    final fleet = context.watch<FleetDataService>();
    final vehicle = fleet.assignedVehicle;
    final today = fleet.todayDriverDay;
    final recent = fleet.recentDriverDays
        .where((d) => d.id != today?.id)
        .take(2)
        .toList();
    final hasActiveDay = today?.status == DriverDayStatus.active;
    final hasDriverData = vehicle != null || today != null || recent.isNotEmpty;

    if (fleet.driverLoading && !hasDriverData) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (fleet.error != null && !hasDriverData) {
      return SafeArea(
        child: LoadErrorView(
          title: 'Dashboard unavailable',
          message: fleet.error!,
          onRetry: _loadData,
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DriverPageHeader(
                title: user.firstName.isNotEmpty ? '${user.firstName} 👋' : 'Hello 👋',
                subtitle: 'Good morning,',
                subtitleFirst: true,
                trailing: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.lavender,
                  child: Text(user.avatarLetter, style: AppTextStyles.sectionTitle()),
                ),
              ),
              if (fleet.error != null) ...[
                const SizedBox(height: 16),
                LoadErrorView(
                  title: 'Couldn\'t refresh',
                  message: fleet.error!,
                  onRetry: _loadData,
                  compact: true,
                ),
              ],
              const SizedBox(height: 24),
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
                    Text('Taxi', style: AppTextStyles.label()),
                    if (vehicle != null) ...[
                      Text(vehicle.displayName, style: AppTextStyles.sectionTitle()),
                      const SizedBox(height: 4),
                      Text(vehicle.registrationNumber, style: AppTextStyles.body(color: AppColors.textSecondary)),
                    ] else
                      Text(
                        'No vehicle assigned',
                        style: AppTextStyles.sectionTitle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              HeroStatCard(
                label: hasActiveDay ? "Today's Net" : 'No active day',
                value: CurrencyFormatter.format(today?.net ?? 0),
                subtitle: hasActiveDay
                    ? 'Earnings ${CurrencyFormatter.format(today!.totalEarnings)}'
                    : 'Check in to start',
                accentColor: AppColors.mint,
              ),
              const SizedBox(height: 20),
              if (!hasActiveDay)
                PrimaryButton(
                  label: 'Check In',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => context.push(AppRouter.driverCheckIn),
                )
              else ...[
                Text('TODAY', style: AppTextStyles.label()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PastelDataCard(
                        title: 'Earnings',
                        amount: today!.totalEarnings,
                        color: AppColors.lavender,
                        onTap: () => context.push(AppRouter.driverEarnings),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PastelDataCard(
                        title: 'Fuel',
                        amount: today.fuelTotal,
                        color: AppColors.mint,
                        onTap: () => context.push(AppRouter.driverFuel),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                PastelDataCard(
                  title: 'Other Expenses',
                  amount: today.expenseTotal,
                  color: AppColors.peach,
                  onTap: () => context.push(AppRouter.driverAddExpense),
                ),
                const SizedBox(height: 20),
                Text('QUICK ACTIONS', style: AppTextStyles.label()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickAction(
                      icon: Icons.payments_outlined,
                      label: 'Earnings',
                      color: AppColors.lavender,
                      onTap: () => context.push(AppRouter.driverEarnings),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.local_gas_station_outlined,
                      label: 'Fuel',
                      color: AppColors.mint,
                      onTap: () => context.push(AppRouter.driverFuel),
                    ),
                    const SizedBox(width: 12),
                    _QuickAction(
                      icon: Icons.build_outlined,
                      label: 'Expense',
                      color: AppColors.peach,
                      onTap: () => context.push(AppRouter.driverAddExpense),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('RECENT', style: AppTextStyles.label()),
                  GestureDetector(
                    onTap: () => DriverShellScope.of(context)?.onTabSelected(3),
                    child: Text(
                      'View All >',
                      style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recent.isEmpty)
                Text(
                  'No past days yet',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                )
              else
                ...recent.asMap().entries.map((entry) {
                  final day = entry.value;
                  final colors = [AppColors.lavender, AppColors.mint, AppColors.peach];
                  return TimelineEntry(
                    date: day.date,
                    earnings: day.totalEarnings,
                    fuel: day.fuelTotal,
                    expenses: day.expenseTotal,
                    isLast: entry.key == recent.length - 1,
                    color: colors[entry.key % colors.length],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 8),
              Text(label, style: AppTextStyles.body().copyWith(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
