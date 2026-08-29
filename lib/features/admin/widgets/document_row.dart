import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../models/models.dart';
import '../../../services/storage_service.dart';

class DocumentRow extends StatelessWidget {
  const DocumentRow({
    super.key,
    required this.document,
    this.onApprove,
    this.onReject,
  });

  final DriverDocument document;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  String get _label => switch (document.documentType) {
        DocumentType.id => 'ID Document',
        DocumentType.pdp => 'PDP',
      };

  String get _statusLabel => switch (document.status) {
        DocumentStatus.approved => 'Approved',
        DocumentStatus.pending => 'Pending',
        DocumentStatus.rejected => 'Rejected',
      };

  Color get _statusColor => switch (document.status) {
        DocumentStatus.approved => AppColors.mint,
        DocumentStatus.pending => AppColors.peach,
        DocumentStatus.rejected => AppColors.error.withOpacity(0.15),
      };

  Future<void> _view(BuildContext context) async {
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
              TextButton(onPressed: () => _view(context), child: const Text('View')),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(_statusLabel, style: AppTextStyles.label()),
          ),
          if (onApprove != null || onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  ),
                if (onReject != null && onApprove != null) const SizedBox(width: 8),
                if (onApprove != null)
                  Expanded(
                    child: FilledButton(
                      onPressed: onApprove,
                      style: FilledButton.styleFrom(backgroundColor: AppColors.textPrimary),
                      child: const Text('Approve'),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
