import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/models.dart';
import '../../../services/fleet_data_service.dart';

class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final docs = FleetDataService.driverDocuments;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Documents', style: AppTextStyles.sectionTitle()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Your uploaded documents',
            style: AppTextStyles.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ...docs.map((doc) => _DocumentCard(document: doc)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () => context.push(AppRouter.driverUploadDocument),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
            ),
            child: const Text('Upload New Document'),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document});

  final DriverDocument document;

  String get _label => switch (document.documentType) {
        DocumentType.id => 'ID Document',
        DocumentType.pdp => 'PDP',
      };

  Color get _statusColor => switch (document.status) {
        DocumentStatus.approved => AppColors.mint,
        DocumentStatus.pending => AppColors.peach,
        DocumentStatus.rejected => AppColors.error.withOpacity(0.2),
      };

  String get _statusLabel => switch (document.status) {
        DocumentStatus.approved => 'Approved',
        DocumentStatus.pending => 'Pending Review',
        DocumentStatus.rejected => 'Rejected',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.skyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description_outlined),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_label, style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600)),
                    if (document.uploadedAt != null)
                      Text(
                        'Uploaded ${DateFormat('d MMM yyyy').format(document.uploadedAt!)}',
                        style: AppTextStyles.body(color: AppColors.textSecondary).copyWith(fontSize: 13),
                      ),
                  ],
                ),
              ),
              TextButton(onPressed: () {}, child: const Text('View')),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(_statusLabel, style: AppTextStyles.label()),
          ),
        ],
      ),
    );
  }
}
