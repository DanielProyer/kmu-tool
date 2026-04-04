import 'dart:convert';
import '../../data/models/beleg_scan_result.dart';
import '../supabase/supabase_service.dart';

/// Ruft die Edge Function parse-beleg auf und gibt das OCR-Ergebnis zurück.
class BelegScanService {
  static Future<BelegScanResult> scanBeleg({
    required String imageBase64,
    required String mimeType,
  }) async {
    final response = await SupabaseService.client.functions.invoke(
      'parse-beleg',
      body: {
        'image_base64': imageBase64,
        'mime_type': mimeType,
      },
    );

    if (response.status != 200) {
      final error = response.data is Map ? response.data['error'] : 'Unbekannter Fehler';
      throw Exception('Beleg-Scan fehlgeschlagen: $error');
    }

    final data = response.data is String
        ? jsonDecode(response.data) as Map<String, dynamic>
        : response.data as Map<String, dynamic>;

    if (data.containsKey('error')) {
      throw Exception(data['error']);
    }

    return BelegScanResult.fromJson(data);
  }
}
