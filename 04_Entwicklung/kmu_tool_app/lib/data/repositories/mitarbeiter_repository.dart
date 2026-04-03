import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/mitarbeiter.dart';

class MitarbeiterRepository {
  static const _table = 'mitarbeiter';

  static Future<List<Mitarbeiter>> getAll() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('nachname');
    return data.map((json) => Mitarbeiter.fromJson(json)).toList();
  }

  static Future<Mitarbeiter?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Mitarbeiter.fromJson(data);
  }

  static Future<void> save(Mitarbeiter mitarbeiter) async {
    await SupabaseService.client.from(_table).upsert(mitarbeiter.toJson());
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
