import '../../services/supabase/supabase_service.dart';
import '../models/artikel_foto.dart';

class ArtikelFotoRepository {
  static const _table = 'artikel_fotos';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<ArtikelFoto>> getByArtikel(String artikelId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('artikel_id', artikelId)
        .order('sortierung');
    return data.map((json) => ArtikelFoto.fromJson(json)).toList();
  }

  static Future<void> create(ArtikelFoto foto) async {
    await SupabaseService.client.from(_table).insert(foto.toJson());
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  static Future<void> setHauptbild(String artikelId, String fotoId) async {
    // Reset all
    await SupabaseService.client
        .from(_table)
        .update({'ist_hauptbild': false})
        .eq('artikel_id', artikelId)
        .eq('user_id', _userId);
    // Set new
    await SupabaseService.client
        .from(_table)
        .update({'ist_hauptbild': true})
        .eq('id', fotoId)
        .eq('user_id', _userId);
  }
}
