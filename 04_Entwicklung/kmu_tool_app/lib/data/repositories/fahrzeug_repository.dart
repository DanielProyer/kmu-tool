import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/fahrzeug.dart';

class FahrzeugRepository {
  static const _table = 'fahrzeuge';

  static Future<List<Fahrzeug>> getAll({bool? aktiv}) async {
    final userId = await BetriebService.getDataOwnerId();
    var query = SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false);
    if (aktiv != null) {
      query = query.eq('aktiv', aktiv);
    }
    final data = await query.order('bezeichnung');
    return data.map((json) => Fahrzeug.fromJson(json)).toList();
  }

  static Future<Fahrzeug?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Fahrzeug.fromJson(data);
  }

  static Future<void> save(Fahrzeug fahrzeug) async {
    await SupabaseService.client.from(_table).upsert(fahrzeug.toJson());
  }

  static Future<void> delete(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .update({'is_deleted': true})
        .eq('id', id)
        .eq('user_id', userId);
  }
}
