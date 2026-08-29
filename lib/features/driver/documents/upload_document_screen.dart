import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/document_picker.dart';
import '../../../core/widgets/pill_segment.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/upload_tile.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key, this.initialType});

  final DocumentType? initialType;

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  late DocumentType _type;
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? DocumentType.id;
  }

  Future<void> _pickFile() async {
    try {
      final file = await DocumentPicker.pickDocument();
      if (file == null || !mounted) return;
      setState(() => _selectedFile = file);
    } on DocumentPickerException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not select file — please try again');
    }
  }

  Future<void> _save() async {
    final file = _selectedFile;
    if (file == null || file.bytes == null) {
      AppToast.warning(context, 'Please select a document first');
      return;
    }

    final driverId = context.read<AuthService>().currentUser?.id;
    if (driverId == null) {
      AppToast.error(context, 'You must be signed in to upload documents');
      return;
    }

    final extension = DocumentPicker.extensionFor(file);
    if (extension == null) {
      AppToast.warning(context, 'Unsupported file type — use PDF, JPG, or PNG');
      return;
    }

    setState(() => _isUploading = true);

    final fleet = context.read<FleetDataService>();
    final error = await fleet.uploadDriverDocument(
      driverId: driverId,
      documentType: _type,
      bytes: file.bytes!,
      extension: extension,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (error != null) {
      AppToast.error(context, error);
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
    final isBusy = _isUploading || context.watch<FleetDataService>().isSubmitting;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: isBusy ? null : () => context.pop(),
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
                onChanged: (v) {
                  if (isBusy) return;
                  setState(() {
                    _type = v;
                    _selectedFile = null;
                  });
                },
                labelBuilder: (t) => t == DocumentType.id ? 'ID Document' : 'PDP',
              ),
              const SizedBox(height: 32),
              UploadTile(
                label: _type == DocumentType.id ? 'ID Document' : 'PDP',
                subtitle: 'PDF or image — tap to select',
                isUploaded: _selectedFile != null,
                fileName: _selectedFile?.name,
                onTap: isBusy ? null : _pickFile,
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
              PrimaryButton(
                label: isBusy ? 'Uploading...' : 'Upload',
                onPressed: isBusy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
