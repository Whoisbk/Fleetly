import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum DocumentPickSource { camera, photo, file }

class DocumentPicker {
  DocumentPicker._();

  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  static bool get _useSourceSheet =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  /// Opens a source chooser on phones, or the system file picker on desktop.
  static Future<PlatformFile?> pickFromSource(
    BuildContext context, {
    String title = 'Add document',
    String subtitle = 'Take a photo with the phone camera, or choose a file already saved.',
  }) async {
    if (!_useSourceSheet) {
      return pickDocument();
    }

    final source = await showModalBottomSheet<DocumentPickSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(title, style: AppTextStyles.sectionTitle()),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: AppTextStyles.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take photo'),
                  subtitle: const Text('Open the phone camera'),
                  onTap: () => Navigator.pop(context, DocumentPickSource.camera),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Photo library'),
                  subtitle: const Text('Photos already saved on the phone'),
                  onTap: () => Navigator.pop(context, DocumentPickSource.photo),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Browse files'),
                  subtitle: const Text('PDF, JPG, or PNG'),
                  onTap: () => Navigator.pop(context, DocumentPickSource.file),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return null;
    return pickDocument(source: source);
  }

  /// Opens the system file picker for PDFs and images.
  /// Returns `null` if the user cancels or the file cannot be read.
  static Future<PlatformFile?> pickDocument({
    DocumentPickSource source = DocumentPickSource.file,
  }) async {
    if (source == DocumentPickSource.camera) {
      return _takePhoto();
    }

    try {
      final result = source == DocumentPickSource.photo
          ? await FilePicker.platform.pickFiles(
              type: FileType.image,
              withData: true,
            )
          : await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: allowedExtensions,
              withData: true,
            );

      if (result == null || result.files.isEmpty) return null;

      final file = result.files.first;
      final bytes = await _readBytes(file);
      if (bytes == null) return null;

      return PlatformFile(
        name: file.name,
        size: bytes.length,
        bytes: bytes,
        path: file.path,
        identifier: file.identifier,
      );
    } on MissingPluginException {
      throw const DocumentPickerException(
        'File picker is not available. Stop the app completely and run it again.',
      );
    } on PlatformException catch (e) {
      throw DocumentPickerException(
        e.message ?? 'Could not open the file picker',
      );
    }
  }

  static Future<PlatformFile?> _takePhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80,
        maxWidth: 2000,
      );
      if (photo == null) return null;

      final bytes = await photo.readAsBytes();
      final rawName = photo.name.trim();
      final fileName = rawName.isEmpty || extensionForName(rawName) == null
          ? 'receipt.jpg'
          : rawName;

      return PlatformFile(
        name: fileName,
        size: bytes.length,
        bytes: bytes,
        path: photo.path,
      );
    } on MissingPluginException {
      throw const DocumentPickerException(
        'Camera is not available. Stop the app completely and run it again.',
      );
    } on PlatformException catch (e) {
      final message = (e.message ?? '').toLowerCase();
      if (e.code == 'camera_access_denied' ||
          message.contains('permission') ||
          message.contains('denied')) {
        throw const DocumentPickerException(
          'Allow camera access to take a photo.',
        );
      }
      throw DocumentPickerException(e.message ?? 'Could not open the camera');
    }
  }

  static Future<PlatformFile> fromDropped({
    required String name,
    required Uint8List bytes,
  }) async {
    final fileName = name.trim().isEmpty ? 'document' : name;
    if (extensionForName(fileName) == null) {
      throw const DocumentPickerException(
        'Unsupported file type — use PDF, JPG, or PNG',
      );
    }
    return PlatformFile(
      name: fileName,
      size: bytes.length,
      bytes: bytes,
    );
  }

  static Future<Uint8List?> _readBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (!kIsWeb && file.path != null) {
      return File(file.path!).readAsBytes();
    }
    return null;
  }

  static String? extensionFor(PlatformFile file) =>
      extensionForName(file.extension ?? file.name);

  static String? extensionForName(String name) {
    final lower = name.toLowerCase();
    final fromDot = lower.contains('.') ? lower.split('.').last : lower;
    if (allowedExtensions.contains(fromDot)) return fromDot;

    return switch (lower) {
      final n when n.endsWith('.pdf') => 'pdf',
      final n when n.endsWith('.jpeg') => 'jpeg',
      final n when n.endsWith('.jpg') => 'jpg',
      final n when n.endsWith('.png') => 'png',
      final n when n.endsWith('.webp') => 'webp',
      _ => null,
    };
  }
}

class DocumentPickerException implements Exception {
  const DocumentPickerException(this.message);

  final String message;

  @override
  String toString() => message;
}
