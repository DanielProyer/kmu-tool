import '../../services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';
import '../models/buchung.dart';

class BuchungRepository {
  static const _table = 'buchungen';

  Future<List<Buchung>> getAll() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('datum', ascending: false);
    return data.map((json) => Buchung.fromJson(json)).toList();
  }

  Future<Buchung?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    return data != null ? Buchung.fromJson(data) : null;
  }

  /// Returns all Buchungen where soll_konto or haben_konto matches the given
  /// Kontonummer.
  Future<List<Buchung>> getByKonto(int kontonummer) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .or('soll_konto.eq.$kontonummer,haben_konto.eq.$kontonummer')
        .order('datum', ascending: false);
    return data.map((json) => Buchung.fromJson(json)).toList();
  }

  Future<List<Buchung>> getByMonat(int monat, {int? jahr}) async {
    final userId = await BetriebService.getDataOwnerId();
    var query = SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('monat', monat);
    if (jahr != null) {
      // Filter by year using datum column range
      final start = DateTime(jahr, monat, 1);
      final end = (monat < 12)
          ? DateTime(jahr, monat + 1, 1)
          : DateTime(jahr + 1, 1, 1);
      query = query
          .gte('datum', start.toIso8601String())
          .lt('datum', end.toIso8601String());
    }
    final data = await query.order('datum', ascending: false);
    return data.map((json) => Buchung.fromJson(json)).toList();
  }

  Future<List<Buchung>> getByRechnung(String rechnungId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('rechnung_id', rechnungId)
        .order('datum', ascending: false);
    return data.map((json) => Buchung.fromJson(json)).toList();
  }

  Future<void> save(Buchung buchung) async {
    await SupabaseService.client.from(_table).upsert(buchung.toJson());
  }

  Future<void> delete(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }
}
