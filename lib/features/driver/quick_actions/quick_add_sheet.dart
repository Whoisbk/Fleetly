import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/models.dart';
import '../../../services/fleet_data_service.dart';

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final today = fleet.todayDriverDay;
    final hasActiveDay = today?.status == DriverDayStatus.active;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Quick Actions', style: AppTextStyles.sectionTitle()),
          const SizedBox(height: 8),
          Text(
            hasActiveDay ? 'Add to today\'s log' : 'Check in first to start logging',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          if (!hasActiveDay)
            PrimaryButton(
              label: 'Check In',
              icon: Icons.play_arrow_rounded,
              onPressed: () {
                Navigator.pop(context);
                context.push(AppRouter.driverCheckIn);
              },
            )
          else ...[
            _ActionTile(
              icon: Icons.payments_outlined,
              label: 'Add Earnings',
              color: AppColors.lavender,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.driverEarnings);
              },
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.local_gas_station_outlined,
              label: 'Add Fuel',
              color: AppColors.mint,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.driverFuel);
              },
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.build_outlined,
              label: 'Add Expense',
              color: AppColors.peach,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.driverAddExpense);
              },
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.nightlight_round,
              label: 'End Day',
              color: AppColors.skyBlue,
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.driverEndDay);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
