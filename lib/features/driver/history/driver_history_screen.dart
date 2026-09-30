import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../core/widgets/timeline_entry.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
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
    final days = fleet.recentDriverDays;

    if (fleet.driverLoading && days.isEmpty) {
      return const SafeArea(child: Center(child: CircularProgressIndicator()));
    }

    if (fleet.error != null && days.isEmpty) {
      return SafeArea(
        child: LoadErrorView(
          title: 'History unavailable',
          message: fleet.error!,
          onRetry: _refresh,
        ),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: days.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text('History', style: AppTextStyles.pageTitle()),
                  const SizedBox(height: 24),
                  Text(
                    'No days recorded yet',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
                  ),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Text('History', style: AppTextStyles.pageTitle()),
                  const SizedBox(height: 8),
                  Text(
                    'Your recent working days',
                    style: AppTextStyles.body(color: AppColors.textSecondary),
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
                  ...days.asMap().entries.map((entry) {
                    final day = entry.value;
                    final colors = [AppColors.lavender, AppColors.mint, AppColors.peach];
                    return TimelineEntry(
                      date: day.date,
                      earnings: day.totalEarnings,
                      fuel: day.fuelTotal,
                      expenses: day.expenseTotal,
                      isLast: entry.key == days.length - 1,
                      color: colors[entry.key % colors.length],
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
