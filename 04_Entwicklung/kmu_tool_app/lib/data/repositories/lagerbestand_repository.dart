import '../../services/supabase/supabase_service.dart';
import '../models/lagerbestand.dart';

class LagerbestandRepository {
  static const _table = 'lagerbestaende';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<Lagerbestand>> getByArtikel(String artikelId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, lagerorte(bezeichnung, typ)')
        .eq('user_id', _userId)
        .eq('artikel_id', artikelId);
    return data.map((json) => Lagerbestand.fromJson(json)).toList();
  }

  static Future<Map<String, double>> getGesamtbestand(
      String artikelId) async {
    final data = await SupabaseService.client
        .from('v_artikel_gesamtbestand')
        .select()
        .eq('user_id', _userId)
        .eq('artikel_id', artikelId)
        .maybeSingle();
    if (data == null) {
      return {'gesamtmenge': 0, 'reserviert': 0, 'verfuegbar': 0};
    }
    return {
      'gesamtmenge': (data['gesamtmenge'] as num?)?.toDouble() ?? 0,
      'reserviert': (data['gesamt_reserviert'] as num?)?.toDouble() ?? 0,
      'verfuegbar': (data['verfuegbar'] as num?)?.toDouble() ?? 0,
    };
  }

  static Future<List<Lagerbestand>> getByLagerort(String lagerortId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, lagerorte(bezeichnung, typ)')
        .eq('user_id', _userId)
        .eq('lagerort_id', lagerortId);
    return data.map((json) => Lagerbestand.fromJson(json)).toList();
  }
}
