import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _date = DateTime.now();

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

  @override
  void dispose() {
    _odometerController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Enter your starting odometer reading');
      return;
    }

    final user = context.read<AuthService>().currentUser;
    final fleet = context.read<FleetDataService>();
    final vehicle = fleet.assignedVehicle;

    if (user == null) return;
    if (vehicle == null) {
      AppToast.warning(context, 'No vehicle assigned — contact your admin');
      return;
    }

    final error = await fleet.startDay(
      driverId: user.id,
      vehicleId: vehicle.id,
      startingOdometer: FleetDataService.parseOdometer(_odometerController.text),
    );

    if (!mounted) return;

    if (error != null) {
      AppToast.warning(context, error);
      return;
    }

    context.pop();
    AppToast.success(context, 'Day started — you\'re checked in!');
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                    value: '${vehicle.displayName} (${vehicle.registrationNumber})',
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
                TextFormField(
                  controller: _odometerController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Starting KM',
                    hintText: '123,450',
                  ),
                  validator: (v) => FormValidators.odometer(v),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Start Day',
                  icon: Icons.play_arrow_rounded,
                  isLoading: fleet.isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
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
          Text(value, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
