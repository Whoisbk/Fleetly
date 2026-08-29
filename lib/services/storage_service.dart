import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../models/models.dart';
import 'supabase_service.dart';

abstract final class StorageService {
  static const fleetFilesBucket = 'fleet-files';

  static Future<String?> getSignedUrl(String path) async {
    if (!AppConstants.isSupabaseConfigured) return null;

    final normalized = _stripBucketPrefix(path);
    try {
      return await SupabaseService.client.storage
          .from(fleetFilesBucket)
          .createSignedUrl(normalized, 3600);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getDocumentUrl(DriverDocument document) {
    final path = _normalizeDocumentPath(
      document.filePath,
      document.driverId,
      document.documentType,
    );
    return getSignedUrl(path);
  }

  static Future<String?> getReceiptUrl(String receiptPath) {
    return getSignedUrl(receiptPath);
  }

  static Future<String?> getProfileImageUrl(String driverId) {
    return getSignedUrl('$driverId/profile/profile.jpg');
  }

  /// Uploads ID or PDP document. Returns the storage path on success.
  static Future<String> uploadDriverDocument({
    required String driverId,
    required DocumentType type,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = documentPath(driverId: driverId, type: type, extension: extension);
    await _upload(
      path: path,
      bytes: bytes,
      contentType: _mimeForExtension(extension),
    );
    return path;
  }

  /// Uploads a profile photo. Returns the storage path on success.
  static Future<String> uploadProfileImage({
    required String driverId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = profilePath(driverId: driverId, extension: extension);
    await _upload(
      path: path,
      bytes: bytes,
      contentType: _mimeForExtension(extension),
    );
    return path;
  }

  /// Uploads an expense receipt. Returns the storage path on success.
  static Future<String> uploadExpenseReceipt({
    required String driverId,
    required String expenseId,
    required Uint8List bytes,
    required String extension,
  }) async {
    final path = receiptPath(
      driverId: driverId,
      expenseId: expenseId,
      extension: extension,
    );
    await _upload(
      path: path,
      bytes: bytes,
      contentType: _mimeForExtension(extension),
    );
    return path;
  }

  static String documentPath({
    required String driverId,
    required DocumentType type,
    required String extension,
  }) {
    final base = type == DocumentType.pdp ? 'pdp' : 'id';
    return '$driverId/documents/$base.$extension';
  }

  static String profilePath({
    required String driverId,
    required String extension,
  }) {
    return '$driverId/profile/profile.$extension';
  }

  static String receiptPath({
    required String driverId,
    required String expenseId,
    required String extension,
  }) {
    return '$driverId/receipts/$expenseId.$extension';
  }

  static Future<void> _upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (!AppConstants.isSupabaseConfigured) {
      throw StateError('Supabase is not configured');
    }

    await SupabaseService.client.storage.from(fleetFilesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );
  }

  static String _stripBucketPrefix(String filePath) {
    var path = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    for (final prefix in [
      '$fleetFilesBucket/',
      'driver-documents/',
      'driver-profile-images/',
      'expense-receipts/',
    ]) {
      if (path.startsWith(prefix)) {
        path = path.substring(prefix.length);
      }
    }
    return path;
  }

  static String _normalizeDocumentPath(
    String filePath,
    String driverId,
    DocumentType type,
  ) {
    final path = _stripBucketPrefix(filePath);
    if (path.contains('/documents/')) return path;

    // Legacy paths: {driver_id}/id.pdf
    if (path.contains('/')) return path;

    final suffix = type == DocumentType.pdp ? 'pdp.pdf' : 'id.pdf';
    return '$driverId/documents/$suffix';
  }

  static String _mimeForExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    return switch (ext) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'jpg' || 'jpeg' => 'image/jpeg',
      _ => 'application/octet-stream',
    };
  }
}
