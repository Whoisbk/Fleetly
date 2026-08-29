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

class PendingApprovalsScreen extends StatefulWidget {
  const PendingApprovalsScreen({super.key});

  @override
  State<PendingApprovalsScreen> createState() => _PendingApprovalsScreenState();
}

class _PendingApprovalsScreenState extends State<PendingApprovalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fleet = context.read<FleetDataService>();
      await fleet.loadAdminDashboard();
      for (final driver in fleet.pendingDrivers) {
        await fleet.loadDriverDocuments(driver.id);
      }
    });
  }

  Future<void> _approve(UserProfile driver) async {
    final fleet = context.read<FleetDataService>();
    final error = await fleet.approveDriver(driver.id);
    if (!mounted) return;
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    AppToast.success(context, '${driver.firstName} approved');
  }

  Future<void> _reject(UserProfile driver) async {
    final fleet = context.read<FleetDataService>();
    final error = await fleet.rejectDriver(driver.id);
    if (!mounted) return;
    if (error != null) {
      AppToast.warning(context, error);
      return;
    }
    AppToast.success(context, '${driver.firstName} rejected');
  }

  Future<void> _updateDoc(String documentId, DocumentStatus status) async {
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
    final drivers = fleet.pendingDrivers;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Pending Approvals', style: AppTextStyles.sectionTitle()),
      ),
      body: fleet.adminLoading && drivers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : drivers.isEmpty
              ? Center(
                  child: Text('No pending applications', style: AppTextStyles.body(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: drivers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    final docs = fleet.documentsForDriver(driver.id);
                    return _DriverApprovalCard(
                      driver: driver,
                      documents: docs,
                      isSubmitting: fleet.isSubmitting,
                      onApprove: () => _approve(driver),
                      onReject: () => _reject(driver),
                      onLoadDocs: () => fleet.loadDriverDocuments(driver.id),
                      onApproveDoc: (id) => _updateDoc(id, DocumentStatus.approved),
                      onRejectDoc: (id) => _updateDoc(id, DocumentStatus.rejected),
                    );
                  },
                ),
    );
  }
}

class _DriverApprovalCard extends StatelessWidget {
  const _DriverApprovalCard({
    required this.driver,
    required this.documents,
    required this.isSubmitting,
    required this.onApprove,
    required this.onReject,
    required this.onLoadDocs,
    required this.onApproveDoc,
    required this.onRejectDoc,
  });

  final UserProfile driver;
  final List<DriverDocument> documents;
  final bool isSubmitting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onLoadDocs;
  final void Function(String documentId) onApproveDoc;
  final void Function(String documentId) onRejectDoc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(driver.fullName, style: AppTextStyles.sectionTitle())),
              DriverStatusBadge(status: driver.status),
            ],
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Phone', value: driver.phone),
          _InfoRow(label: 'Email', value: driver.email),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Documents', style: AppTextStyles.label()),
              TextButton(onPressed: onLoadDocs, child: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 8),
          if (documents.isEmpty)
            Text('No documents uploaded', style: AppTextStyles.body(color: AppColors.textSecondary))
          else
            ...documents.map((doc) => DocumentRow(
                  document: doc,
                  onApprove: doc.status == DocumentStatus.pending ? () => onApproveDoc(doc.id) : null,
                  onReject: doc.status == DocumentStatus.pending ? () => onRejectDoc(doc.id) : null,
                )),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Reject',
                  onPressed: isSubmitting ? null : onReject,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Approve',
                  isLoading: isSubmitting,
                  onPressed: onApprove,
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body(color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
