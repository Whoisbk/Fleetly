import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../models/models.dart';
import '../../../services/fleet_data_service.dart';
import '../widgets/document_row.dart';
import '../widgets/driver_status_badge.dart';

class DriverDetailScreen extends StatefulWidget {
  const DriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final fleet = context.read<FleetDataService>();
    await fleet.ensureDriverLoaded(widget.driverId);
    await fleet.loadDriverDocuments(widget.driverId);
    await fleet.loadDriverAssignment(widget.driverId);
    if (fleet.vehicles.isEmpty) await fleet.loadAllVehicles();

    final assigned = fleet.assignedVehicleForDriver(widget.driverId);
    if (assigned != null && mounted) {
      setState(() => _selectedVehicleId = assigned.id);
    }
  }

  Future<void> _updateStatus(UserStatus status, String successMessage) async {
    final fleet = context.read<FleetDataService>();
    final error = await fleet.updateDriverStatus(widget.driverId, status);
    if (!mounted) return;
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    AppToast.success(context, successMessage);
    if (status == UserStatus.rejected) context.pop();
  }

  Future<void> _assignVehicle() async {
    if (_selectedVehicleId == null) {
      AppToast.warning(context, 'Select a vehicle first');
      return;
    }

    final fleet = context.read<FleetDataService>();
    final error = await fleet.assignVehicleToDriver(
      driverId: widget.driverId,
      vehicleId: _selectedVehicleId!,
    );

    if (!mounted) return;
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    AppToast.success(context, 'Vehicle assigned');
  }

  Future<void> _updateDocumentStatus(String documentId, DocumentStatus status) async {
    final fleet = context.read<FleetDataService>();
    final error = await fleet.updateDocumentStatus(documentId: documentId, status: status);
    if (!mounted) return;
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    AppToast.success(context, 'Document updated');
  }

  @override
  Widget build(BuildContext context) {
    final fleet = context.watch<FleetDataService>();
    final driver = fleet.driverById(widget.driverId);
    final documents = fleet.documentsForDriver(widget.driverId);
    final assignedVehicle = fleet.assignedVehicleForDriver(widget.driverId);

    if (driver == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(driver.fullName, style: AppTextStyles.sectionTitle()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.lavender,
                  child: Text(driver.avatarLetter, style: AppTextStyles.metric().copyWith(fontSize: 32)),
                ),
                const SizedBox(height: 12),
                Text(driver.fullName, style: AppTextStyles.sectionTitle()),
                const SizedBox(height: 8),
                DriverStatusBadge(status: driver.status),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _InfoRow(label: 'Email', value: driver.email),
          _InfoRow(label: 'Phone', value: driver.phone),
          const SizedBox(height: 24),
          Text('ASSIGNED VEHICLE', style: AppTextStyles.label()),
          const SizedBox(height: 12),
          if (assignedVehicle != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(assignedVehicle.displayName, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
                  Text(assignedVehicle.registrationNumber, style: AppTextStyles.body(color: AppColors.textSecondary)),
                ],
              ),
            ),
          if (fleet.vehicles.isEmpty)
            Text('Add vehicles in Fleet tab first', style: AppTextStyles.body(color: AppColors.textSecondary))
          else ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedVehicleId,
              decoration: InputDecoration(
                labelText: 'Assign vehicle',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: fleet.vehicles
                  .map((v) => DropdownMenuItem(
                        value: v.id,
                        child: Text('${v.registrationNumber} — ${v.displayName}'),
                      ))
                  .toList(),
              onChanged: fleet.isSubmitting ? null : (v) => setState(() => _selectedVehicleId = v),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: assignedVehicle == null ? 'Assign Vehicle' : 'Change Vehicle',
              isLoading: fleet.isSubmitting,
              onPressed: _assignVehicle,
            ),
          ],
          const SizedBox(height: 28),
          Text('DOCUMENTS', style: AppTextStyles.label()),
          const SizedBox(height: 12),
          if (documents.isEmpty)
            Text('No documents uploaded', style: AppTextStyles.body(color: AppColors.textSecondary))
          else
            ...documents.map((doc) => DocumentRow(
                  document: doc,
                  onApprove: doc.status == DocumentStatus.pending
                      ? () => _updateDocumentStatus(doc.id, DocumentStatus.approved)
                      : null,
                  onReject: doc.status == DocumentStatus.pending
                      ? () => _updateDocumentStatus(doc.id, DocumentStatus.rejected)
                      : null,
                )),
          const SizedBox(height: 28),
          if (driver.status == UserStatus.pending) ...[
            PrimaryButton(
              label: 'Approve Driver',
              isLoading: fleet.isSubmitting,
              onPressed: () => _updateStatus(UserStatus.approved, '${driver.firstName} approved'),
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'Reject Application',
              onPressed: fleet.isSubmitting ? null : () => _updateStatus(UserStatus.rejected, '${driver.firstName} rejected'),
            ),
          ],
          if (driver.status == UserStatus.approved) ...[
            SecondaryButton(
              label: 'Suspend Driver',
              onPressed: fleet.isSubmitting ? null : () => _updateStatus(UserStatus.suspended, '${driver.firstName} suspended'),
            ),
          ],
          if (driver.status == UserStatus.suspended) ...[
            PrimaryButton(
              label: 'Reactivate Driver',
              isLoading: fleet.isSubmitting,
              onPressed: () => _updateStatus(UserStatus.approved, '${driver.firstName} reactivated'),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
