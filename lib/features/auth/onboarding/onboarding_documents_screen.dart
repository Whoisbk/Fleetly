import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/document_picker.dart';
import '../../../core/widgets/drop_upload_target.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/upload_tile.dart';
import '../../../models/models.dart';
import '../../../services/auth_service.dart';
import '../../../services/fleet_data_service.dart';

class OnboardingDocumentsScreen extends StatefulWidget {
  const OnboardingDocumentsScreen({super.key});

  @override
  State<OnboardingDocumentsScreen> createState() =>
      _OnboardingDocumentsScreenState();
}

class _OnboardingDocumentsScreenState extends State<OnboardingDocumentsScreen> {
  String? _idFileName;
  String? _pdpFileName;
  DocumentType? _uploadingType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
  }

  Future<void> _loadExisting() async {
    final driverId = context.read<AuthService>().currentUser?.id;
    if (driverId == null) return;

    final fleet = context.read<FleetDataService>();
    await fleet.loadDriverDocuments(driverId);
    if (!mounted) return;

    DriverDocument? docFor(DocumentType type) {
      final matches = fleet
          .documentsForDriver(driverId)
          .where((d) => d.documentType == type);
      return matches.isEmpty ? null : matches.first;
    }

    String fileNameOf(DriverDocument doc) => doc.filePath.split('/').last;

    setState(() {
      final idDoc = docFor(DocumentType.id);
      final pdpDoc = docFor(DocumentType.pdp);
      _idFileName = idDoc != null ? fileNameOf(idDoc) : _idFileName;
      _pdpFileName = pdpDoc != null ? fileNameOf(pdpDoc) : _pdpFileName;
    });
  }

  Future<void> _pickAndUpload(DocumentType type) async {
    if (_uploadingType != null) return;

    try {
      final file = await DocumentPicker.pickFromSource(context);
      if (file == null || !mounted) return;
      await _upload(type, file);
    } on DocumentPickerException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Could not select file — please try again');
    }
  }

  Future<void> _upload(DocumentType type, PlatformFile file) async {
    if (file.bytes == null) {
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

    setState(() => _uploadingType = type);

    final error = await context.read<FleetDataService>().uploadDriverDocument(
          driverId: driverId,
          documentType: type,
          bytes: file.bytes!,
          extension: extension,
        );

    if (!mounted) return;
    setState(() => _uploadingType = null);

    if (error != null) {
      AppToast.error(context, error);
      return;
    }

    setState(() {
      if (type == DocumentType.id) {
        _idFileName = file.name;
      } else {
        _pdpFileName = file.name;
      }
    });

    AppToast.success(
      context,
      '${type == DocumentType.id ? 'ID' : 'PDP'} document uploaded',
    );
  }

  void _continue() {
    if (_idFileName == null || _pdpFileName == null) {
      AppToast.warning(context, 'Upload both your ID and PDP to continue');
      return;
    }
    context.go(AppRouter.onboardingReview);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _uploadingType != null ||
        context.watch<FleetDataService>().isSubmitting;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Upload documents', style: AppTextStyles.pageTitle()),
              const SizedBox(height: 8),
              Text(
                'Step 2 of 3 — ID and PDP',
                style: AppTextStyles.body(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              DropUploadTarget(
                enabled: !isBusy,
                onDropped: (file) => _upload(DocumentType.id, file),
                onError: (message) => AppToast.error(context, message),
                builder: (hovering) => UploadTile(
                  label: 'ID Document',
                  subtitle: isBusy && _uploadingType == DocumentType.id
                      ? 'Uploading...'
                      : hovering
                          ? 'Drop to upload'
                          : 'Tap or drop a file from your computer',
                  isUploaded: _idFileName != null,
                  isHighlighted: hovering,
                  fileName: _idFileName,
                  onTap: isBusy ? null : () => _pickAndUpload(DocumentType.id),
                ),
              ),
              const SizedBox(height: 12),
              DropUploadTarget(
                enabled: !isBusy,
                onDropped: (file) => _upload(DocumentType.pdp, file),
                onError: (message) => AppToast.error(context, message),
                builder: (hovering) => UploadTile(
                  label: 'PDP',
                  subtitle: isBusy && _uploadingType == DocumentType.pdp
                      ? 'Uploading...'
                      : hovering
                          ? 'Drop to upload'
                          : 'Tap or drop a file from your computer',
                  isUploaded: _pdpFileName != null,
                  isHighlighted: hovering,
                  fileName: _pdpFileName,
                  onTap: isBusy ? null : () => _pickAndUpload(DocumentType.pdp),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
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
                        'On the iPhone Simulator, drag a photo from your Mac onto the Simulator window, then tap and choose Photo library.',
                        style: AppTextStyles.body().copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue',
                onPressed: isBusy ? null : _continue,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: isBusy
                      ? null
                      : () => context.read<AuthService>().signOut(),
                  child: Text(
                    'Sign out',
                    style: AppTextStyles.body()
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
