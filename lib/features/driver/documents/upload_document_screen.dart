import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/widgets/pill_segment.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/upload_tile.dart';
import '../../../models/models.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key, this.initialType});

  final DocumentType? initialType;

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  late DocumentType _type;
  bool _uploaded = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? DocumentType.id;
  }

  void _save() {
    if (!_uploaded) {
      AppToast.warning(context, 'Please upload a document first');
      return;
    }
    context.pop();
    AppToast.success(
      context,
      '${_type == DocumentType.id ? 'ID' : 'PDP'} document uploaded',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Upload Document', style: AppTextStyles.sectionTitle()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Document Type', style: AppTextStyles.label()),
              const SizedBox(height: 12),
              PillSegment<DocumentType>(
                options: DocumentType.values,
                selected: _type,
                onChanged: (v) => setState(() {
                  _type = v;
                  _uploaded = false;
                }),
                labelBuilder: (t) => t == DocumentType.id ? 'ID Document' : 'PDP',
              ),
              const SizedBox(height: 32),
              UploadTile(
                label: _type == DocumentType.id ? 'ID Document' : 'PDP',
                subtitle: 'PDF or image — tap to upload',
                isUploaded: _uploaded,
                fileName: _uploaded ? '${_type.name}.pdf' : null,
                onTap: () => setState(() => _uploaded = true),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.peach.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Documents are reviewed by the fleet administrator before approval.',
                        style: AppTextStyles.body().copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(label: 'Upload', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
