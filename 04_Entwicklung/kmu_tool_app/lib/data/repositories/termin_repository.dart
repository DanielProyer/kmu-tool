import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/termin.dart';

class TerminRepository {
  static const _table = 'termine';

  static Future<List<Termin>> getAll({DateTime? von, DateTime? bis}) async {
    final userId = await BetriebService.getDataOwnerId();
    var query = SupabaseService.client
        .from(_table)
        .select('*, kunden(firma, vorname, nachname), auftraege(auftrags_nr)')
        .eq('user_id', userId)
        .eq('is_deleted', false);
    if (von != null) {
      query = query.gte('datum', von.toIso8601String().split('T')[0]);
    }
    if (bis != null) {
      query = query.lte('datum', bis.toIso8601String().split('T')[0]);
    }
    final data = await query.order('datum').order('start_zeit');
    return data.map((json) => Termin.fromJson(json)).toList();
  }

  static Future<List<Termin>> getByDatum(DateTime datum) async {
    final userId = await BetriebService.getDataOwnerId();
    final dateStr = datum.toIso8601String().split('T')[0];
    final data = await SupabaseService.client
        .from(_table)
        .select('*, kunden(firma, vorname, nachname), auftraege(auftrags_nr)')
        .eq('user_id', userId)
        .eq('datum', dateStr)
        .eq('is_deleted', false)
        .order('start_zeit');
    return data.map((json) => Termin.fromJson(json)).toList();
  }

  static Future<Termin?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select('*, kunden(firma, vorname, nachname), auftraege(auftrags_nr)')
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Termin.fromJson(data);
  }

  static Future<void> save(Termin termin) async {
    await SupabaseService.client.from(_table).upsert(termin.toJson());
  }

  static Future<void> delete(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .update({'is_deleted': true})
        .eq('id', id)
        .eq('user_id', userId);
  }

  /// Zählt Termine für heute.
  static Future<int> countHeute() async {
    final userId = await BetriebService.getDataOwnerId();
    final heute = DateTime.now().toIso8601String().split('T')[0];
    final data = await SupabaseService.client
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('datum', heute)
        .eq('is_deleted', false)
        .neq('status', 'abgesagt');
    return data.length;
  }
}
