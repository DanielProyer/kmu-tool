import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/mitarbeiter_berechtigung.dart';

class MitarbeiterBerechtigungRepository {
  static const _table = 'mitarbeiter_berechtigungen';

  static Future<List<MitarbeiterBerechtigung>> getForMitarbeiter(
      String mitarbeiterId) async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('mitarbeiter_id', mitarbeiterId)
        .order('modul');
    return data
        .map((json) => MitarbeiterBerechtigung.fromJson(json))
        .toList();
  }

  static Future<void> saveAll(
      List<MitarbeiterBerechtigung> berechtigungen) async {
    if (berechtigungen.isEmpty) return;
    await SupabaseService.client
        .from(_table)
        .upsert(berechtigungen.map((b) => b.toJson()).toList());
  }

  static Future<void> deleteForMitarbeiter(String mitarbeiterId) async {
    final userId = await BetriebService.getDataOwnerId();
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('mitarbeiter_id', mitarbeiterId)
        .eq('user_id', userId);
  }
}
