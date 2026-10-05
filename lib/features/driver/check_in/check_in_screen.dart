import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';
import '../../../services/distance_tracking_service.dart';
import '../../../services/fleet_data_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _date = DateTime.now();
  bool _starting = false;
  String? _locationMessage;
  LocationSettingsTarget _settingsTarget = LocationSettingsTarget.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureDataLoaded());
  }

  void _ensureDataLoaded() {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      context.read<FleetDataService>().loadDriverDashboard(user.id);
    }
  }

  Future<void> _openSettings() async {
    if (_settingsTarget == LocationSettingsTarget.app) {
      await Geolocator.openAppSettings();
    } else if (_settingsTarget == LocationSettingsTarget.device) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> _submit() async {
    if (_starting) return;

    final user = context.read<AuthService>().currentUser;
    final fleet = context.read<FleetDataService>();
    final tracker = context.read<DistanceTrackingService>();
    final vehicle = fleet.assignedVehicle;

    if (user == null) return;
    if (vehicle == null) {
      AppToast.warning(context, 'No vehicle assigned — contact your admin');
      return;
    }

    setState(() {
      _starting = true;
      _locationMessage = null;
    });

    final gate = await tracker.ensureReady();
    if (!mounted) return;
    if (!gate.granted) {
      setState(() {
        _starting = false;
        _locationMessage = gate.message;
        _settingsTarget = gate.settings;
      });
      return;
    }

    final error = await fleet.startDay(
      driverId: user.id,
      vehicleId: vehicle.id,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _starting = false);
      AppToast.warning(context, error);
      return;
    }

    final day = fleet.todayDriverDay;
    if (day != null) {
      await tracker.start(driverDayId: day.id, serverKm: day.distanceKm);
    }

    if (!mounted) return;
    context.pop();
    AppToast.success(context, 'Day started — distance tracking is on');
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final vehicle = fleet.assignedVehicle;
    final dateLabel = DateFormat('d MMMM yyyy').format(_date);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Check In', style: AppTextStyles.sectionTitle()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Check-In", style: AppTextStyles.pageTitle()),
                    const SizedBox(height: 8),
                    Text(
                      'Start your working day',
                      style: AppTextStyles.body(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),
                    if (vehicle != null)
                      _InfoCard(
                        label: 'Taxi',
                        value:
                            '${vehicle.displayName} (${vehicle.registrationNumber})',
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.peach,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'No vehicle assigned. Ask your admin to assign a taxi before checking in.',
                          style: AppTextStyles.body(),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _InfoCard(label: 'Date', value: dateLabel),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.skyBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Distance', style: AppTextStyles.label()),
                          const SizedBox(height: 4),
                          Text(
                            'Kilometres are tracked from your location from the moment you start until you end the day. You do not enter them yourself.',
                            style: AppTextStyles.body(),
                          ),
                        ],
                      ),
                    ),
                    if (_locationMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _locationMessage!,
                        style: AppTextStyles.body(color: AppColors.error),
                      ),
                      if (_settingsTarget != LocationSettingsTarget.none)
                        TextButton(
                          onPressed: _openSettings,
                          child: const Text('Open Settings'),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(
                label: 'Start Day',
                icon: Icons.play_arrow_rounded,
                isLoading: _starting || fleet.isSubmitting,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.label()),
          const SizedBox(height: 4),
          Text(value,
              style:
                  AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
