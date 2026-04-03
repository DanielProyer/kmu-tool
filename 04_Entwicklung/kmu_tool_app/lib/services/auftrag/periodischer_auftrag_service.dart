import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';

class PeriodischerAuftragService {
  /// Prüft ob periodische Aufträge fällig sind und gibt die Anzahl zurück.
  static Future<int> getFaelligeCount() async {
    final userId = await BetriebService.getDataOwnerId();
    final heute = DateTime.now().toIso8601String().split('T')[0];
    final data = await SupabaseService.client
        .from('auftraege')
        .select('id')
        .eq('user_id', userId)
        .eq('auftrag_typ', 'periodisch')
        .eq('is_deleted', false)
        .lte('naechste_ausfuehrung', heute);
    return data.length;
  }

  /// Berechnet das nächste Ausführungsdatum basierend auf Intervall.
  static DateTime berechneNaechsteDatum(DateTime aktuell, String intervall) {
    switch (intervall) {
      case 'woechentlich':
        return aktuell.add(const Duration(days: 7));
      case 'monatlich':
        return DateTime(aktuell.year, aktuell.month + 1, aktuell.day);
      case 'quartalsweise':
        return DateTime(aktuell.year, aktuell.month + 3, aktuell.day);
      case 'halbjaehrlich':
        return DateTime(aktuell.year, aktuell.month + 6, aktuell.day);
      case 'jaehrlich':
        return DateTime(aktuell.year + 1, aktuell.month, aktuell.day);
      default:
        return aktuell;
    }
  }
}
