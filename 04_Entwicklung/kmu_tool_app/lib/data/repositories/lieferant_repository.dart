import '../../services/supabase/supabase_service.dart';
import '../models/lieferant.dart';

class LieferantRepository {
  static const _table = 'lieferanten';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<Lieferant>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_deleted', false)
        .order('firma');
    return data.map((json) => Lieferant.fromJson(json)).toList();
  }

  static Future<Lieferant?> getById(String id) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return data != null ? Lieferant.fromJson(data) : null;
  }

  static Future<List<Lieferant>> search(String query) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('is_deleted', false)
        .or('firma.ilike.%$query%,kontaktperson.ilike.%$query%')
        .order('firma')
        .limit(20);
    return data.map((json) => Lieferant.fromJson(json)).toList();
  }

  static Future<void> save(Lieferant lieferant) async {
    await SupabaseService.client.from(_table).upsert(lieferant.toJson());
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
