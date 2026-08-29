import '../core/constants/app_constants.dart';
import '../models/models.dart';
import 'supabase_service.dart';

abstract final class StorageService {
  static const driverDocumentsBucket = 'driver-documents';
  static const expenseReceiptsBucket = 'expense-receipts';

  static Future<String?> getSignedUrl(String bucket, String path) async {
    if (!AppConstants.isSupabaseConfigured) return null;

    final normalized = path.startsWith('/') ? path.substring(1) : path;
    try {
      return await SupabaseService.client.storage
          .from(bucket)
          .createSignedUrl(normalized, 3600);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getDocumentUrl(DriverDocument document) {
    final path = _normalizeDocumentPath(document.filePath, document.driverId, document.documentType);
    return getSignedUrl(driverDocumentsBucket, path);
  }

  static Future<String?> getReceiptUrl(String receiptPath) {
    return getSignedUrl(expenseReceiptsBucket, receiptPath);
  }

  static String _normalizeDocumentPath(
    String filePath,
    String driverId,
    DocumentType type,
  ) {
    if (filePath.contains('/')) {
      return filePath.replaceFirst('$driverDocumentsBucket/', '');
    }
    final suffix = type == DocumentType.pdp ? 'pdp.pdf' : 'id.pdf';
    return '$driverId/$suffix';
  }
}
