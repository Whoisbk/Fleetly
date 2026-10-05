import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/distance_formatter.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../services/auth_service.dart';
import '../../../services/distance_tracking_service.dart';
import '../../../services/fleet_data_service.dart';

class EndDayScreen extends StatefulWidget {
  const EndDayScreen({super.key});

  @override
  State<EndDayScreen> createState() => _EndDayScreenState();
}

class _EndDayScreenState extends State<EndDayScreen> {
  final _notesController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final user = context.read<AuthService>().currentUser;
    final fleet = context.read<FleetDataService>();
    final tracker = context.read<DistanceTrackingService>();
    final today = fleet.todayDriverDay;

    if (user == null || today == null) {
      AppToast.warning(context, 'No active day to submit');
      return;
    }

    setState(() => _submitting = true);
    await tracker.pause();
    final km = tracker.kmForDay(today.id, today.distanceKm);

    final error = await fleet.endDay(
      driverId: user.id,
      driverDayId: today.id,
      distanceKm: km,
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (error != null) {
      await tracker.resume();
      if (!mounted) return;
      setState(() => _submitting = false);
      AppToast.warning(context, error);
      return;
    }

    await tracker.finish();
    if (!mounted) return;
    context.pop();
    AppToast.success(
        context, 'Day submitted — ${formatDistanceKm(km)} traveled');
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final tracker = context.watch<DistanceTrackingService>();
    final today = fleet.todayDriverDay;

    if (today == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
          title: Text('End Day', style: AppTextStyles.sectionTitle()),
        ),
        body: Center(
          child: Text(
            'No active day to submit',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final km = tracker.kmForDay(today.id, today.distanceKm);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('End Day', style: AppTextStyles.sectionTitle()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submit Day', style: AppTextStyles.pageTitle()),
              const SizedBox(height: 8),
              Text(
                'Review and close your working day',
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    SummaryRow(label: 'Earnings', amount: today.totalEarnings),
                    SummaryRow(label: 'Fuel', amount: today.fuelTotal),
                    SummaryRow(label: 'Expenses', amount: today.expenseTotal),
                    SummaryRow(
                      label: 'Distance',
                      amount: 0,
                      valueText: formatDistanceKm(km),
                    ),
                    const Divider(height: 24),
                    SummaryRow(label: 'Net', amount: today.net, isNet: true),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Distance is calculated from your route and cannot be edited.',
                style: AppTextStyles.body(color: AppColors.textSecondary)
                    .copyWith(fontSize: 13),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Anything to note about today?',
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Submit Day',
                icon: Icons.check_rounded,
                isLoading: _submitting || fleet.isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
