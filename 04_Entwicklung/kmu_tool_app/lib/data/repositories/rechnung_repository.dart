import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/rechnung.dart';

class RechnungRepository {
  static const _table = 'rechnungen';

  Future<List<Rechnung>> getAll() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('datum', ascending: false);
    return data.map((json) => Rechnung.fromJson(json)).toList();
  }

  Future<Rechnung?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null ? Rechnung.fromJson(data) : null;
  }

  Future<List<Rechnung>> getByKunde(String kundeId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('kunde_id', kundeId)
        .order('datum', ascending: false);
    return data.map((json) => Rechnung.fromJson(json)).toList();
  }

  Future<List<Rechnung>> getByAuftrag(String auftragId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('auftrag_id', auftragId)
        .order('datum', ascending: false);
    return data.map((json) => Rechnung.fromJson(json)).toList();
  }

  Future<List<Rechnung>> getByStatus(String status) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('status', status)
        .order('datum', ascending: false);
    return data.map((json) => Rechnung.fromJson(json)).toList();
  }

  /// Returns all invoices with status entwurf, gesendet, or gemahnt.
  Future<List<Rechnung>> getOffene() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .inFilter('status', ['entwurf', 'gesendet', 'gemahnt'])
        .order('faellig_am', ascending: true);
    return data.map((json) => Rechnung.fromJson(json)).toList();
  }

  Future<void> save(Rechnung rechnung) async {
    await SupabaseService.client.from(_table).upsert(rechnung.toJson());
  }

  Future<void> updateStatus(String id, String status) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .update({'status': status})
        .eq('id', id)
        .eq('user_id', userId);
  }

  Future<int> count() async {
    final userId = await BetriebService.getDataOwnerId();
    final result = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .count();
    return result.count;
  }

  /// Sum of total_brutto for all open invoices (entwurf, gesendet, gemahnt).
  Future<double> summeOffene() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select('total_brutto')
        .eq('user_id', userId)
        .inFilter('status', ['entwurf', 'gesendet', 'gemahnt']);
    double summe = 0;
    for (final row in data) {
      summe += (row['total_brutto'] as num?)?.toDouble() ?? 0;
    }
    return summe;
  }
}
