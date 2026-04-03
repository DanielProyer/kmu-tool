import '../../services/supabase/supabase_service.dart';
import '../models/lagerbewegung.dart';

class LagerbewegungRepository {
  static const _table = 'lagerbewegungen';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<Lagerbewegung>> getByArtikel(String artikelId,
      {int limit = 50}) async {
    final data = await SupabaseService.client
        .from(_table)
        .select(
            '*, lagerorte!lagerbewegungen_lagerort_id_fkey(bezeichnung), ziel_lagerorte:lagerorte!lagerbewegungen_ziel_lagerort_id_fkey(bezeichnung)')
        .eq('user_id', _userId)
        .eq('artikel_id', artikelId)
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((json) => Lagerbewegung.fromJson(json)).toList();
  }

  static Future<void> create(Lagerbewegung bewegung) async {
    await SupabaseService.client.from(_table).insert(bewegung.toJson());
  }

  static Future<List<Lagerbewegung>> getRecent({int limit = 20}) async {
    final data = await SupabaseService.client
        .from(_table)
        .select(
            '*, lagerorte!lagerbewegungen_lagerort_id_fkey(bezeichnung), ziel_lagerorte:lagerorte!lagerbewegungen_ziel_lagerort_id_fkey(bezeichnung)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(limit);
    return data.map((json) => Lagerbewegung.fromJson(json)).toList();
  }
}
