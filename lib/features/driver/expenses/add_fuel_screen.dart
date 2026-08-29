import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/upload_tile.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class AddFuelScreen extends StatefulWidget {
  const AddFuelScreen({super.key});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _litresController = TextEditingController();
  final _stationController = TextEditingController();
  bool _receiptUploaded = false;

  @override
  void dispose() {
    _amountController.dispose();
    _litresController.dispose();
    _stationController.dispose();
    super.dispose();
  }

  String? _buildDescription() {
    final station = _stationController.text.trim();
    final litres = _litresController.text.trim();
    if (station.isEmpty && litres.isEmpty) return null;
    if (station.isNotEmpty && litres.isNotEmpty) return '$station — ${litres}L';
    if (station.isNotEmpty) return station;
    return '${litres}L';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Please enter a valid fuel amount');
      return;
    }

    final user = context.read<AuthService>().currentUser;
    final fleet = context.read<FleetDataService>();
    final today = fleet.todayDriverDay;
    final vehicle = fleet.assignedVehicle;

    if (user == null || today == null) {
      AppToast.warning(context, 'Check in first to add fuel');
      return;
    }

    if (today.status != DriverDayStatus.active) {
      AppToast.warning(context, 'Today\'s day is already submitted');
      return;
    }

    if (vehicle == null) {
      AppToast.warning(context, 'No vehicle assigned');
      return;
    }

    final error = await fleet.addExpenseEntry(
      driverId: user.id,
      driverDayId: today.id,
      vehicleId: vehicle.id,
      type: ExpenseType.fuel,
      amount: FleetDataService.parseAmount(_amountController.text),
      description: _buildDescription(),
    );

    if (!mounted) return;

    if (error != null) {
      AppToast.warning(context, error);
      return;
    }

    context.pop();
    AppToast.success(context, 'Fuel expense saved');
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
        title: Text('Add Fuel', style: AppTextStyles.sectionTitle()),
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
                Text('Fuel Expense', style: AppTextStyles.pageTitle()),
                const SizedBox(height: 8),
                Text(
                  'Record petrol spent today',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: 'R ',
                  ),
                  validator: FormValidators.amount,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _litresController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Litres (optional)',
                    hintText: '25.4',
                  ),
                  validator: FormValidators.optionalAmount,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _stationController,
                  decoration: const InputDecoration(
                    labelText: 'Station',
                    hintText: 'Shell, Engen, BP...',
                  ),
                ),
                const SizedBox(height: 20),
                UploadTile(
                  label: 'Receipt',
                  subtitle: 'Optional — tap to upload',
                  isUploaded: _receiptUploaded,
                  fileName: _receiptUploaded ? 'receipt.jpg' : null,
                  onTap: () => setState(() => _receiptUploaded = true),
                ),
                const SizedBox(height: 32),
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
