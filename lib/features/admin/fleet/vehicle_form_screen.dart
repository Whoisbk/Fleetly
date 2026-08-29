import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/form_validators.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../services/fleet_data_service.dart';

class VehicleFormScreen extends StatefulWidget {
  const VehicleFormScreen({super.key, this.vehicleId});

  final String? vehicleId;

  bool get isEditing => vehicleId != null;

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final fleet = context.read<FleetDataService>();
        if (fleet.vehicles.isEmpty) fleet.loadAllVehicles();
        _populateFromVehicle(fleet.vehicleById(widget.vehicleId!));
      });
    }
  }

  void _populateFromVehicle(dynamic vehicle) {
    if (vehicle == null) return;
    _registrationController.text = vehicle.registrationNumber;
    _makeController.text = vehicle.make;
    _modelController.text = vehicle.model;
    if (vehicle.year != null) _yearController.text = vehicle.year.toString();
    if (vehicle.color != null) _colorController.text = vehicle.color!;
    setState(() {});
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  int? _parseYear() {
    final text = _yearController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final fleet = context.read<FleetDataService>();
    final year = _parseYear();
    final color = _colorController.text.trim();

    final error = widget.isEditing
        ? await fleet.updateVehicle(
            vehicleId: widget.vehicleId!,
            registrationNumber: _registrationController.text,
            make: _makeController.text,
            model: _modelController.text,
            year: year,
            color: color.isEmpty ? null : color,
          )
        : await fleet.createVehicle(
            registrationNumber: _registrationController.text,
            make: _makeController.text,
            model: _modelController.text,
            year: year,
            color: color.isEmpty ? null : color,
          );

    if (!mounted) return;
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    AppToast.success(context, widget.isEditing ? 'Vehicle updated' : 'Vehicle added');
    context.pop();
  }

  Future<void> _delete() async {
    if (!widget.isEditing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete vehicle?'),
        content: const Text('This cannot be undone if the vehicle has driver history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final error = await context.read<FleetDataService>().deleteVehicle(widget.vehicleId!);
    if (!mounted) return;
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    AppToast.success(context, 'Vehicle deleted');
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(
          widget.isEditing ? 'Edit Vehicle' : 'Add Vehicle',
          style: AppTextStyles.sectionTitle(),
        ),
        actions: widget.isEditing
            ? [
                IconButton(
                  onPressed: fleet.isSubmitting ? null : _delete,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _Field(
                controller: _registrationController,
                label: 'Registration Number',
                validator: (v) => FormValidators.required(v, field: 'Registration'),
              ),
              const SizedBox(height: 16),
              _Field(
                controller: _makeController,
                label: 'Make',
                validator: (v) => FormValidators.required(v, field: 'Make'),
              ),
              const SizedBox(height: 16),
              _Field(
                controller: _modelController,
                label: 'Model',
                validator: (v) => FormValidators.required(v, field: 'Model'),
              ),
              const SizedBox(height: 16),
              _Field(
                controller: _yearController,
                label: 'Year (optional)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _Field(controller: _colorController, label: 'Color (optional)'),
              const SizedBox(height: 32),
              PrimaryButton(
                label: widget.isEditing ? 'Save Changes' : 'Add Vehicle',
                isLoading: fleet.isSubmitting,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
