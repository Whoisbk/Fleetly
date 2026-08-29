import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/summary_row.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class EndDayScreen extends StatefulWidget {
  const EndDayScreen({super.key});

  @override
  State<EndDayScreen> createState() => _EndDayScreenState();
}

class _EndDayScreenState extends State<EndDayScreen> {
  final _formKey = GlobalKey<FormState>();
  final _endingKmController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _endingKmController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Please fix the errors before submitting');
      return;
    }

    final user = context.read<AuthService>().currentUser;
    final fleet = context.read<FleetDataService>();
    final today = fleet.todayDriverDay;

    if (user == null || today == null) {
      AppToast.warning(context, 'No active day to submit');
      return;
    }

    final error = await fleet.endDay(
      driverId: user.id,
      driverDayId: today.id,
      endingOdometer: FleetDataService.parseOdometer(_endingKmController.text),
      notes: _notesController.text,
    );

    if (!mounted) return;

    if (error != null) {
      AppToast.warning(context, error);
      return;
    }

    context.pop();
    AppToast.success(context, 'Day submitted successfully!');
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
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
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
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
                      const Divider(height: 24),
                      SummaryRow(label: 'Net', amount: today.net, isNet: true),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _endingKmController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Ending KM',
                    hintText: today.startingOdometer != null
                        ? '${today.startingOdometer! + 100}'
                        : '123,550',
                  ),
                  validator: (v) => FormValidators.odometer(
                    v,
                    minValue: today.startingOdometer,
                  ),
                ),
                const SizedBox(height: 16),
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
