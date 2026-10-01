import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../models/models.dart';
import '../../../core/widgets/load_error_view.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';
import '../../../services/storage_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDocuments());
  }

  Future<void> _loadDocuments() async {
    final driverId = context.read<AuthService>().currentUser?.id;
    if (driverId == null) return;
    await context.read<FleetDataService>().loadDriverDocuments(driverId);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final fleet = context.watch<FleetDataService>();
    final driverId = auth.currentUser?.id;
    final docs = driverId == null ? const <DriverDocument>[] : fleet.documentsForDriver(driverId);
    final showLoadError = fleet.error != null && docs.isEmpty && !fleet.driverLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Documents', style: AppTextStyles.sectionTitle()),
      ),
      body: RefreshIndicator(
        onRefresh: _loadDocuments,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Your uploaded documents',
              style: AppTextStyles.body(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            if (showLoadError)
              LoadErrorView(
                title: 'Documents unavailable',
                message: fleet.error!,
                onRetry: _loadDocuments,
              )
            else if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No documents uploaded yet',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
              )
            else
              ...docs.map((doc) => _DocumentCard(document: doc)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () async {
                await context.push(AppRouter.driverUploadDocument);
                if (mounted) await _loadDocuments();
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: const Text('Upload New Document'),
            ),
          ],
        ),
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

  Future<void> _viewDocument(BuildContext context) async {
    final url = await StorageService.getDocumentUrl(document);
    if (!context.mounted) return;

    if (url == null) {
      AppToast.warning(context, 'Document preview not available');
      return;
    }

    AppToast.info(context, 'Document URL ready — open in browser: $url');
  }

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
                    Text(
                      _label,
                      style: AppTextStyles.body().copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (document.uploadedAt != null)
                      Text(
                        'Uploaded ${DateFormat('d MMM yyyy').format(document.uploadedAt!)}',
                        style: AppTextStyles.body(color: AppColors.textSecondary)
                            .copyWith(fontSize: 13),
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _viewDocument(context),
                child: const Text('View'),
              ),
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
