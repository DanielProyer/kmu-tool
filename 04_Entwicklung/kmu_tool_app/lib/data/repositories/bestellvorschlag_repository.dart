import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/bestellvorschlag.dart';

class BestellvorschlagRepository {
  static const _table = 'bestellvorschlaege';

  static Future<List<Bestellvorschlag>> getAll({String? status}) async {
    final userId = await BetriebService.getDataOwnerId();
    var query = SupabaseService.client
        .from(_table)
        .select('*, artikel(bezeichnung, artikelnummer, einheit), lieferanten(firma)')
        .eq('user_id', userId)
        .eq('is_deleted', false);
    if (status != null) {
      query = query.eq('status', status);
    }
    final data = await query.order('created_at', ascending: false);
    return data.map((json) => Bestellvorschlag.fromJson(json)).toList();
  }

  static Future<Bestellvorschlag?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select('*, artikel(bezeichnung, artikelnummer, einheit), lieferanten(firma)')
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null ? Bestellvorschlag.fromJson(data) : null;
  }

  static Future<void> save(Bestellvorschlag vorschlag) async {
    await SupabaseService.client.from(_table).upsert(vorschlag.toJson());
  }

  static Future<void> updateStatus(String id, String status) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .update({'status': status})
        .eq('id', id)
        .eq('user_id', userId);
  }

  static Future<void> delete(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .update({'is_deleted': true})
        .eq('id', id)
        .eq('user_id', userId);
  }

  static Future<bool> hasOpenForArtikel(String artikelId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('artikel_id', artikelId)
        .eq('status', 'offen')
        .eq('is_deleted', false)
        .limit(1);
    return data.isNotEmpty;
  }
}
