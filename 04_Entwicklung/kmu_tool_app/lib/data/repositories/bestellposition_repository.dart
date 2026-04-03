import '../../services/supabase/supabase_service.dart';
import '../models/bestellposition.dart';

class BestellpositionRepository {
  static const _table = 'bestellpositionen';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<Bestellposition>> getByBestellung(
      String bestellungId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, artikel(bezeichnung, artikelnummer, einheit)')
        .eq('user_id', _userId)
        .eq('bestellung_id', bestellungId)
        .order('created_at');
    return data.map((json) => Bestellposition.fromJson(json)).toList();
  }

  static Future<void> save(Bestellposition position) async {
    await SupabaseService.client.from(_table).upsert(position.toJson());
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  static Future<void> updateGelieferteMenge(
      String id, double gelieferteMenge) async {
    await SupabaseService.client
        .from(_table)
        .update({'gelieferte_menge': gelieferteMenge})
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
