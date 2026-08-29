import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DocumentPicker {
  DocumentPicker._();

  static const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'webp'];

  /// Opens the system file picker for PDFs and images.
  /// Returns `null` if the user cancels or the file cannot be read.
  static Future<PlatformFile?> pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: !kIsWeb,
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

  static Future<Uint8List?> _readBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes;
    if (!kIsWeb && file.path != null) {
      return File(file.path!).readAsBytes();
    }
    return null;
  }

  static String? extensionFor(PlatformFile file) {
    final fromName = file.extension?.toLowerCase();
    if (fromName != null && fromName.isNotEmpty) return fromName;

    return switch (file.name.toLowerCase()) {
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
