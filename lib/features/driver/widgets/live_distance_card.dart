import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../models/models.dart';
import '../../../services/distance_tracking_service.dart';

class LiveDistanceCard extends StatelessWidget {
  const LiveDistanceCard({super.key, required this.day});

  final DriverDay day;

  @override
  Widget build(BuildContext context) {
    final tracker = context.watch<DistanceTrackingService>();
    final km = tracker.kmForDay(day.id, day.distanceKm);
    final warning = tracker.driverDayId == day.id ? tracker.warning : null;
    final waiting =
        tracker.driverDayId == day.id && tracker.isTracking && !tracker.hasFix;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: warning == null ? AppColors.skyBlue : AppColors.peach,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_outlined, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DISTANCE', style: AppTextStyles.label()),
                Text(formatDistanceKm(km), style: AppTextStyles.metric()),
                const SizedBox(height: 4),
                Text(
                  warning ??
                      (waiting
                          ? 'Waiting for GPS…'
                          : 'Tracked automatically while your day is open'),
                  style: AppTextStyles.body(color: AppColors.textSecondary)
                      .copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
