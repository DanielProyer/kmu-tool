import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/lagerort.dart';

class LagerortRepository {
  static const _table = 'lagerorte';

  static Future<List<Lagerort>> getAll() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('sortierung');
    return data.map((json) => Lagerort.fromJson(json)).toList();
  }

  static Future<Lagerort?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null ? Lagerort.fromJson(data) : null;
  }

  static Future<void> save(Lagerort lagerort) async {
    await SupabaseService.client.from(_table).upsert(lagerort.toJson());
  }

  static Future<void> delete(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .update({'is_deleted': true}).eq('id', id).eq('user_id', userId);
  }

  static Future<int> count() async {
    final userId = await BetriebService.getDataOwnerId();
    final result = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .count();
    return result.count;
  }
}
