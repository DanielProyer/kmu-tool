import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/bankverbindung.dart';

class BankverbindungRepository {
  static const _table = 'bankverbindungen';

  static Future<List<Bankverbindung>> getAll() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('is_deleted', false)
        .order('ist_hauptkonto', ascending: false)
        .order('bezeichnung');
    return data.map((json) => Bankverbindung.fromJson(json)).toList();
  }

  static Future<Bankverbindung?> getById(String id) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Bankverbindung.fromJson(data);
  }

  static Future<Bankverbindung?> getHauptkonto() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('ist_hauptkonto', true)
        .eq('is_deleted', false)
        .maybeSingle();
    if (data == null) return null;
    return Bankverbindung.fromJson(data);
  }

  static Future<void> save(Bankverbindung bankverbindung) async {
    await SupabaseService.client.from(_table).upsert(bankverbindung.toJson());
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
