import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/artikel_lieferant.dart';

class ArtikelLieferantRepository {
  static const _table = 'artikel_lieferanten';

  static Future<List<ArtikelLieferant>> getByArtikel(String artikelId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select('*, lieferanten(firma)')
        .eq('user_id', userId)
        .eq('artikel_id', artikelId)
        .order('ist_hauptlieferant', ascending: false);
    return data.map((json) => ArtikelLieferant.fromJson(json)).toList();
  }

  static Future<List<ArtikelLieferant>> getByLieferant(
      String lieferantId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('lieferant_id', lieferantId);
    return data.map((json) => ArtikelLieferant.fromJson(json)).toList();
  }

  static Future<void> save(ArtikelLieferant al) async {
    await SupabaseService.client.from(_table).upsert(al.toJson());
  }

  static Future<void> delete(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  static Future<void> setHauptlieferant(
      String artikelId, String lieferantId) async {
    final userId = await BetriebService.getDataOwnerId();
    // Reset all for this artikel
    await SupabaseService.client
        .from(_table)
        .update({'ist_hauptlieferant': false})
        .eq('artikel_id', artikelId)
        .eq('user_id', userId);
    // Set the new one
    await SupabaseService.client
        .from(_table)
        .update({'ist_hauptlieferant': true})
        .eq('artikel_id', artikelId)
        .eq('lieferant_id', lieferantId)
        .eq('user_id', userId);
  }
}
