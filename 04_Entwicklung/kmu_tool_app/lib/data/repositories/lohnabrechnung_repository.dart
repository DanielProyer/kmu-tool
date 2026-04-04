import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/lohnabrechnung.dart';

class LohnabrechnungRepository {
  static const _table = 'lohnabrechnungen';

  static Future<List<Lohnabrechnung>> getAll({int? jahr}) async {
    final userId = await BetriebService.getDataOwnerId();
    var query = SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false);
    if (jahr != null) {
      query = query.eq('jahr', jahr);
    }
    final data = await query.order('monat');
    return data.map((json) => Lohnabrechnung.fromJson(json)).toList();
  }

  static Future<List<Lohnabrechnung>> getForMonat(int jahr, int monat) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('jahr', jahr)
        .eq('monat', monat)
        .eq('is_deleted', false)
        .order('created_at');
    return data.map((json) => Lohnabrechnung.fromJson(json)).toList();
  }

  static Future<Lohnabrechnung?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Lohnabrechnung.fromJson(data);
  }

  static Future<void> save(Lohnabrechnung abrechnung) async {
    await SupabaseService.client.from(_table).upsert(abrechnung.toJson());
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
