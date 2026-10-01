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
import '../../../models/models.dart';
import '../../../services/fleet_data_service.dart';
import '../widgets/admin_page_header.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final summary = fleet.fleetSummary;
    final pending = fleet.pendingDrivers;
    final activity = fleet.recentActivity;

    return SafeArea(
      child: fleet.adminLoading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : fleet.error != null && summary == null
              ? LoadErrorView(
                  title: 'Dashboard unavailable',
                  message: fleet.error!,
                  onRetry: () => fleet.loadAdminDashboard(),
                )
              : RefreshIndicator(
              onRefresh: () => fleet.loadAdminDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminPageHeader(
                      title: 'Dashboard',
                      subtitle: 'Fleet overview',
                    ),
                    if (fleet.error != null) ...[
                      const SizedBox(height: 16),
                      LoadErrorView(
                        title: 'Couldn\'t refresh',
                        message: fleet.error!,
                        onRetry: () => fleet.loadAdminDashboard(),
                        compact: true,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text('DRIVERS', style: AppTextStyles.label()),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StatPill(label: 'Total', value: '${summary?.totalDrivers ?? 0}')),
                        const SizedBox(width: 8),
                        Expanded(child: _StatPill(label: 'Active', value: '${summary?.activeDrivers ?? 0}')),
                        const SizedBox(width: 8),
                        Expanded(child: _StatPill(label: 'Pending', value: '${summary?.pendingDrivers ?? 0}')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    HeroStatCard(
                      label: "Today's Fleet",
                      value: CurrencyFormatter.format(summary?.todayNet ?? 0),
                      subtitle: 'Earnings ${CurrencyFormatter.format(summary?.todayEarnings ?? 0)}',
                      accentColor: AppColors.lavender,
                      icon: Icons.analytics_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: PastelDataCard(
                            title: 'Earnings',
                            amount: summary?.todayEarnings ?? 0,
                            color: AppColors.lavender,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PastelDataCard(
                            title: 'Expenses',
                            amount: summary?.todayExpenses ?? 0,
                            color: AppColors.peach,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PENDING APPROVALS', style: AppTextStyles.label()),
                        GestureDetector(
                          onTap: () => context.push(AppRouter.adminApprovals),
                          child: Text(
                            'View All >',
                            style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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
                          Text('${pending.length} drivers waiting', style: AppTextStyles.sectionTitle()),
                          const SizedBox(height: 8),
                          Text(
                            'Review applications and documents',
                            style: AppTextStyles.body(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => context.push(AppRouter.adminApprovals),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            ),
                            child: const Text('View Applications'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('RECENT ACTIVITY', style: AppTextStyles.label()),
                    const SizedBox(height: 12),
                    if (activity.isEmpty)
                      Text('No activity yet', style: AppTextStyles.body(color: AppColors.textSecondary))
                    else
                      ...activity.map((event) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _ActivityItem(
                              title: event.title,
                              subtitle: event.timeLabel,
                              color: _colorForCategory(event.category),
                            ),
                          )),
                  ],
                ),
              ),
            ),
    );
  }

  Color _colorForCategory(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.checkIn:
        return AppColors.mint;
      case ActivityCategory.fuel:
        return AppColors.lavender;
      case ActivityCategory.maintenance:
        return AppColors.peach;
      case ActivityCategory.other:
        return AppColors.skyBlue;
    }
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.sectionTitle()),
          Text(label, style: AppTextStyles.label()),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
          ),
          Text(subtitle, style: AppTextStyles.body(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
