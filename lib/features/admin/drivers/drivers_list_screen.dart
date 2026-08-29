import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/pill_segment.dart';
import '../../../models/models.dart';
import '../../../services/fleet_data_service.dart';
import '../widgets/admin_page_header.dart';
import '../widgets/driver_status_badge.dart';

class DriversListScreen extends StatefulWidget {
  const DriversListScreen({super.key});

  @override
  State<DriversListScreen> createState() => _DriversListScreenState();
}

class _DriversListScreenState extends State<DriversListScreen> {
  UserStatus? _filter;

  List<UserProfile> _filtered(List<UserProfile> drivers) {
    if (_filter == null) return drivers;
    return drivers.where((d) => d.status == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final drivers = _filtered(fleet.allDrivers);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => fleet.loadAllDrivers(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          children: [
            AdminPageHeader(
              title: 'Drivers',
              subtitle: '${fleet.allDrivers.length} registered',
              trailing: IconButton(
                onPressed: () => context.push(AppRouter.adminApprovals),
                icon: const Icon(Icons.pending_actions_outlined),
                tooltip: 'Pending approvals',
              ),
            ),
            const SizedBox(height: 20),
            PillSegment<UserStatus?>(
              options: [null, UserStatus.approved, UserStatus.pending, UserStatus.suspended],
              selected: _filter,
              onChanged: (v) => setState(() => _filter = v),
              labelBuilder: (s) => switch (s) {
                null => 'All',
                UserStatus.approved => 'Approved',
                UserStatus.pending => 'Pending',
                UserStatus.suspended => 'Suspended',
                UserStatus.rejected => 'Rejected',
              },
            ),
            const SizedBox(height: 20),
            if (fleet.adminLoading && drivers.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (drivers.isEmpty)
              Text('No drivers found', style: AppTextStyles.body(color: AppColors.textSecondary))
            else
              ...drivers.map((driver) => _DriverTile(driver: driver)),
          ],
        ),
      ),
    );
  }
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver});

  final UserProfile driver;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('${AppRouter.adminDrivers}/${driver.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.lavender,
              child: Text(driver.avatarLetter, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driver.fullName, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
                  Text(driver.phone, style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13)),
                ],
              ),
            ),
            DriverStatusBadge(status: driver.status),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
