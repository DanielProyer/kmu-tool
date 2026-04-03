import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/artikel_foto.dart';

class ArtikelFotoRepository {
  static const _table = 'artikel_fotos';

  static Future<List<ArtikelFoto>> getByArtikel(String artikelId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('artikel_id', artikelId)
        .order('sortierung');
    return data.map((json) => ArtikelFoto.fromJson(json)).toList();
  }

  static Future<void> create(ArtikelFoto foto) async {
    await SupabaseService.client.from(_table).insert(foto.toJson());
  }

  static Future<void> delete(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  static Future<void> setHauptbild(String artikelId, String fotoId) async {
    final userId = await BetriebService.getDataOwnerId();
    // Reset all
    await SupabaseService.client
        .from(_table)
        .update({'ist_hauptbild': false})
        .eq('artikel_id', artikelId)
        .eq('user_id', userId);
    // Set new
    await SupabaseService.client
        .from(_table)
        .update({'ist_hauptbild': true})
        .eq('id', fotoId)
        .eq('user_id', userId);
  }
}
