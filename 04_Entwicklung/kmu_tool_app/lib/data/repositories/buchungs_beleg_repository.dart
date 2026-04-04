import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;
import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/buchungs_beleg.dart';

class BuchungsBelegRepository {
  static const _table = 'buchungs_belege';
  static const _bucket = 'buchungs-belege';

  Future<List<BuchungsBeleg>> getByBuchung(String buchungId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('buchung_id', buchungId)
        .order('created_at');
    return data.map((json) => BuchungsBeleg.fromJson(json)).toList();
  }

  /// Lädt Datei in Storage hoch und erstellt DB-Eintrag.
  Future<BuchungsBeleg> upload({
    required String buchungId,
    required String dateiname,
    required String dateityp,
    required Uint8List bytes,
    required String belegQuelle,
    String? beschreibung,
  }) async {
    final userId = await BetriebService.getDataOwnerId();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePfad = '$userId/$buchungId/${timestamp}_$dateiname';

    // 1. Datei hochladen
    await SupabaseService.client.storage.from(_bucket).uploadBinary(
          storagePfad,
          bytes,
          fileOptions: FileOptions(contentType: dateityp),
        );

    // 2. DB-Eintrag erstellen
    final beleg = BuchungsBeleg(
      id: '', // wird von DB generiert
      userId: userId,
      buchungId: buchungId,
      dateiname: dateiname,
      dateityp: dateityp,
      storagePfad: storagePfad,
      belegQuelle: belegQuelle,
      beschreibung: beschreibung,
    );

    final result = await SupabaseService.client
        .from(_table)
        .insert(beleg.toJson()..remove('id'))
        .select()
        .single();

    return BuchungsBeleg.fromJson(result);
  }

  Future<void> delete(String belegId) async {
    final userId = await BetriebService.getDataOwnerId();

    // Erst Pfad holen, dann Storage + DB löschen
    final data = await SupabaseService.client
        .from(_table)
        .select('storage_pfad')
        .eq('id', belegId)
        .eq('user_id', userId)
        .maybeSingle();

    if (data != null) {
      final pfad = data['storage_pfad'] as String;
      await SupabaseService.client.storage.from(_bucket).remove([pfad]);
    }

    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('id', belegId)
        .eq('user_id', userId);
  }

  Future<String> getSignedUrl(String storagePfad) async {
    return SupabaseService.client.storage
        .from(_bucket)
        .createSignedUrl(storagePfad, 3600); // 1 Stunde gültig
  }
}
