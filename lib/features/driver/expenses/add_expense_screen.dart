import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/pill_segment.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/upload_tile.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.initialType});

  final ExpenseType? initialType;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  late ExpenseType _type;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _receiptUploaded = false;

  static const _expenseTypes = [
    ExpenseType.maintenance,
    ExpenseType.repair,
    ExpenseType.other,
  ];

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? ExpenseType.maintenance;
    if (_type == ExpenseType.fuel) _type = ExpenseType.maintenance;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      AppToast.warning(context, 'Please fill in all required fields');
      return;
    }

    final user = context.read<AuthService>().currentUser;
    final fleet = context.read<FleetDataService>();
    final today = fleet.todayDriverDay;
    final vehicle = fleet.assignedVehicle;

    if (user == null || today == null) {
      AppToast.warning(context, 'Check in first to add expenses');
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
      type: _type,
      amount: FleetDataService.parseAmount(_amountController.text),
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (error != null) {
      AppToast.warning(context, error);
      return;
    }

    context.pop();
    AppToast.success(context, '${_labelFor(_type)} expense saved');
  }

  String _labelFor(ExpenseType type) => switch (type) {
        ExpenseType.fuel => 'Fuel',
        ExpenseType.maintenance => 'Maintenance',
        ExpenseType.repair => 'Repair',
        ExpenseType.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Add Expense', style: AppTextStyles.sectionTitle()),
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
                Text('Expense', style: AppTextStyles.pageTitle()),
                const SizedBox(height: 8),
                Text(
                  'Record maintenance, repairs, or other costs',
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                Text('Type', style: AppTextStyles.label()),
                const SizedBox(height: 12),
                PillSegment<ExpenseType>(
                  options: _expenseTypes,
                  selected: _type,
                  onChanged: (v) => setState(() => _type = v),
                  labelBuilder: _labelFor,
                ),
                const SizedBox(height: 24),
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
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Went to mechanic — brake pads',
                  ),
                  validator: (v) => FormValidators.required(v, field: 'Description'),
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
