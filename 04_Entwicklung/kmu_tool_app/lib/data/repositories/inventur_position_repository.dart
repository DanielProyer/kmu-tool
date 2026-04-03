import '../../services/supabase/supabase_service.dart';
import '../models/inventur_position.dart';

class InventurPositionRepository {
  static const _table = 'inventur_positionen';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<InventurPosition>> getByInventur(
      String inventurId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select(
            '*, artikel(bezeichnung, artikelnummer, einheit), lagerorte(bezeichnung)')
        .eq('user_id', _userId)
        .eq('inventur_id', inventurId)
        .order('created_at');
    return data.map((json) => InventurPosition.fromJson(json)).toList();
  }

  static Future<void> save(InventurPosition position) async {
    final json = position.toJson();
    await SupabaseService.client.from(_table).upsert(json);
  }

  static Future<void> erfasseZaehlung(
      String id, double istBestand, {String? bemerkung}) async {
    final updates = <String, dynamic>{
      'ist_bestand': istBestand,
      'gezaehlt': true,
    };
    if (bemerkung != null) updates['bemerkung'] = bemerkung;
    await SupabaseService.client
        .from(_table)
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  static Future<void> bulkCreate(List<InventurPosition> positionen) async {
    if (positionen.isEmpty) return;
    final jsonList = positionen.map((p) => p.toJson()).toList();
    await SupabaseService.client.from(_table).insert(jsonList);
  }

  static Future<void> deleteByInventur(String inventurId) async {
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('inventur_id', inventurId)
        .eq('user_id', _userId);
  }
}
