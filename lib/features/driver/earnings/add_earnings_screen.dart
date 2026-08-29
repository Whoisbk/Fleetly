import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class AddEarningsScreen extends StatefulWidget {
  const AddEarningsScreen({super.key});

  @override
  State<AddEarningsScreen> createState() => _AddEarningsScreenState();
}

class _AddEarningsScreenState extends State<AddEarningsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final today = context.read<FleetDataService>().todayDriverDay;
      if (today != null && today.totalEarnings > 0) {
        _amountController.text = today.totalEarnings.toStringAsFixed(
          today.totalEarnings.truncateToDouble() == today.totalEarnings ? 0 : 2,
        );
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Enter a valid earnings amount');
      return;
    }

    final user = context.read<AuthService>().currentUser;
    final fleet = context.read<FleetDataService>();
    final today = fleet.todayDriverDay;

    if (user == null || today == null) {
      AppToast.warning(context, 'Check in first to record earnings');
      return;
    }

    if (today.status != DriverDayStatus.active) {
      AppToast.warning(context, 'Today\'s day is already submitted');
      return;
    }

    final amount = FleetDataService.parseAmount(_amountController.text);
    final error = await fleet.updateEarnings(
      driverId: user.id,
      driverDayId: today.id,
      amount: amount,
    );

    if (!mounted) return;

    if (error != null) {
      AppToast.warning(context, error);
      return;
    }

    context.pop();
    AppToast.success(context, 'Earnings of R${amount.toStringAsFixed(0)} saved');
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Add Earnings', style: AppTextStyles.sectionTitle()),
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
                Text("Today's Earnings", style: AppTextStyles.pageTitle()),
                const SizedBox(height: 8),
                Text(
                  'How much did you make today?',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.lavender,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppTextStyles.metric().copyWith(fontSize: 36),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      prefixText: 'R ',
                      hintText: '0',
                    ),
                    validator: FormValidators.amount,
                  ),
                ),
                const Spacer(),
                PrimaryButton(
                  label: 'Save',
                  isLoading: fleet.isSubmitting,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
