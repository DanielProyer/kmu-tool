import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/inventur.dart';

class InventurRepository {
  static const _table = 'inventuren';

  static Future<List<Inventur>> getAll({String? status}) async {
    final userId = await BetriebService.getDataOwnerId();
    var query = SupabaseService.client
        .from(_table)
        .select('*, lagerorte(bezeichnung)')
        .eq('user_id', userId)
        .eq('is_deleted', false);
    if (status != null) {
      query = query.eq('status', status);
    }
    final data = await query.order('stichtag', ascending: false);

    // Aggregate position counts
    final inventuren = <Inventur>[];
    for (final json in data) {
      final id = json['id'] as String;
      final counts = await SupabaseService.client
          .from('inventur_positionen')
          .select('id, gezaehlt')
          .eq('inventur_id', id);
      json['positionen_gesamt'] = counts.length;
      json['positionen_gezaehlt'] =
          counts.where((c) => c['gezaehlt'] == true).length;
      inventuren.add(Inventur.fromJson(json));
    }
    return inventuren;
  }

  static Future<Inventur?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select('*, lagerorte(bezeichnung)')
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;

    final counts = await SupabaseService.client
        .from('inventur_positionen')
        .select('id, gezaehlt')
        .eq('inventur_id', id);
    data['positionen_gesamt'] = counts.length;
    data['positionen_gezaehlt'] =
        counts.where((c) => c['gezaehlt'] == true).length;

    return Inventur.fromJson(data);
  }

  static Future<void> save(Inventur inventur) async {
    await SupabaseService.client.from(_table).upsert(inventur.toJson());
  }

  static Future<void> updateStatus(String id, String status) async {
    try {
      final userId = await BetriebService.getDataOwnerId();
      await SupabaseService.client
          .from(_table)
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Status-Update fehlgeschlagen: $e');
    }
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
