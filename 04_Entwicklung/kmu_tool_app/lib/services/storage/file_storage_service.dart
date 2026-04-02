import 'dart:typed_data';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

/// Upload/Download für Auftrag-Notizen und -Dateien via Supabase Storage.
class FileStorageService {
  static const _notizenBucket = 'auftrag-notizen';
  static const _dateienBucket = 'auftrag-dateien';

  /// Upload einer Datei. Gibt den Storage-Pfad zurück.
  static Future<String> uploadNotizDatei({
    required String auftragId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$auftragId/$fileName';
    await SupabaseService.client.storage
        .from(_notizenBucket)
        .uploadBinary(path, bytes, retryAttempts: 2);
    return path;
  }

  /// Upload einer Auftrag-Datei.
  static Future<String> uploadAuftragDatei({
    required String auftragId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final path = '$auftragId/$fileName';
    await SupabaseService.client.storage
        .from(_dateienBucket)
        .uploadBinary(path, bytes, retryAttempts: 2);
    return path;
  }

  /// Download-URL generieren (signed, 1h gültig).
  static Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    return SupabaseService.client.storage
        .from(bucket)
        .createSignedUrl(path, expiresInSeconds);
  }

  /// Datei löschen.
  static Future<void> delete({
    required String bucket,
    required String path,
  }) async {
    await SupabaseService.client.storage.from(bucket).remove([path]);
  }

  static String get notizenBucket => _notizenBucket;
  static String get dateienBucket => _dateienBucket;
}
