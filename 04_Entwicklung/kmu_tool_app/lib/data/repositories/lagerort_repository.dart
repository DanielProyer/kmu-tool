import '../../services/supabase/supabase_service.dart';
import '../models/lagerort.dart';

class LagerortRepository {
  static const _table = 'lagerorte';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<Lagerort>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_deleted', false)
        .order('sortierung');
    return data.map((json) => Lagerort.fromJson(json)).toList();
  }

  static Future<Lagerort?> getById(String id) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return data != null ? Lagerort.fromJson(data) : null;
  }

  static Future<void> save(Lagerort lagerort) async {
    await SupabaseService.client.from(_table).upsert(lagerort.toJson());
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_table)
        .update({'is_deleted': true}).eq('id', id).eq('user_id', _userId);
  }

  static Future<int> count() async {
    final result = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_deleted', false)
        .count();
    return result.count;
  }
}
