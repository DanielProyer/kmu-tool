import '../../services/supabase/supabase_service.dart';
import '../models/bestellung.dart';

class BestellungRepository {
  static const _table = 'bestellungen';

  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<Bestellung>> getAll({String? status}) async {
    var query = SupabaseService.client
        .from(_table)
        .select('*, lieferanten(firma)')
        .eq('user_id', _userId)
        .eq('is_deleted', false);
    if (status != null) {
      query = query.eq('status', status);
    }
    final data = await query.order('created_at', ascending: false);
    return data.map((json) => Bestellung.fromJson(json)).toList();
  }

  static Future<Bestellung?> getById(String id) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, lieferanten(firma)')
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return data != null ? Bestellung.fromJson(data) : null;
  }

  static Future<void> save(Bestellung bestellung) async {
    await SupabaseService.client.from(_table).upsert(bestellung.toJson());
  }

  static Future<void> updateStatus(String id, String status) async {
    final updates = <String, dynamic>{'status': status};
    if (status == 'geliefert') {
      updates['liefer_datum'] = DateTime.now().toIso8601String().split('T').first;
    }
    await SupabaseService.client
        .from(_table)
        .update(updates)
        .eq('id', id)
        .eq('user_id', _userId);
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client
        .from(_table)
        .update({'is_deleted': true})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  static Future<String> nextBestellNr() async {
    final data = await SupabaseService.client
        .from(_table)
        .select('bestell_nr')
        .eq('user_id', _userId)
        .order('created_at', ascending: false)
        .limit(1);
    if (data.isEmpty) return 'B-0001';
    final last = data.first['bestell_nr'] as String;
    final match = RegExp(r'(\d+)$').firstMatch(last);
    if (match == null) return 'B-0001';
    final next = int.parse(match.group(1)!) + 1;
    return 'B-${next.toString().padLeft(4, '0')}';
  }

  static Future<void> updateTotal(String id) async {
    final positionen = await SupabaseService.client
        .from('bestellpositionen')
        .select('menge, einzelpreis')
        .eq('bestellung_id', id)
        .eq('user_id', _userId);
    double total = 0;
    for (final p in positionen) {
      total += ((p['menge'] as num?)?.toDouble() ?? 0) *
          ((p['einzelpreis'] as num?)?.toDouble() ?? 0);
    }
    await SupabaseService.client
        .from(_table)
        .update({'total_betrag': total})
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
