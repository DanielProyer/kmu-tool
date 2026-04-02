import '../../services/supabase/supabase_service.dart';
import '../models/buchungs_vorlage.dart';

class BuchungsVorlageRepository {
  static const _table = 'buchungs_vorlagen';

  String get _userId => SupabaseService.currentUser!.id;

  Future<List<BuchungsVorlage>> getAll() async {
    try {
      final data = await SupabaseService.client
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .order('bezeichnung', ascending: true);
      final result =
          data.map((json) => BuchungsVorlage.fromJson(json)).toList();
      if (result.isNotEmpty) return result;
    } catch (_) {
      // Tabelle existiert noch nicht → Fallback
    }
    return _defaultVorlagen();
  }

  Future<List<BuchungsVorlage>> getByTrigger(String trigger) async {
    try {
      final data = await SupabaseService.client
          .from(_table)
          .select()
          .eq('user_id', _userId)
          .eq('auto_trigger', trigger);
      final result =
          data.map((json) => BuchungsVorlage.fromJson(json)).toList();
      if (result.isNotEmpty) return result;
    } catch (_) {
      // Fallback
    }
    return _defaultVorlagen()
        .where((v) => v.autoTrigger == trigger)
        .toList();
  }

  Future<void> save(BuchungsVorlage vorlage) async {
    await SupabaseService.client.from(_table).upsert(vorlage.toJson());
  }

  /// Hardcoded Standard-Buchungsvorlagen als Fallback,
  /// solange die Supabase-Tabelle noch nicht existiert.
  List<BuchungsVorlage> _defaultVorlagen() {
    final uid = _userId;
    return [
      // ── Automatik-Vorlagen (Rechnungs-Trigger) ──
      BuchungsVorlage(
        id: 'default_rechnung_erstellt',
        userId: uid,
        geschaeftsfallId: 'rechnung_erstellt',
        bezeichnung: 'Rechnung erstellt (Nettobetrag)',
        sollKonto: 1100,
        habenKonto: 3000,
        autoTrigger: 'rechnung_erstellt',
      ),
      BuchungsVorlage(
        id: 'default_rechnung_erstellt_mwst',
        userId: uid,
        geschaeftsfallId: 'rechnung_erstellt_mwst',
        bezeichnung: 'Rechnung erstellt (MWST-Anteil)',
        sollKonto: 1100,
        habenKonto: 2200,
        autoTrigger: 'rechnung_erstellt',
      ),
      BuchungsVorlage(
        id: 'default_rechnung_bezahlt',
        userId: uid,
        geschaeftsfallId: 'rechnung_bezahlt',
        bezeichnung: 'Zahlungseingang Rechnung',
        sollKonto: 1020,
        habenKonto: 1100,
        autoTrigger: 'rechnung_bezahlt',
      ),
      BuchungsVorlage(
        id: 'default_rechnung_storniert',
        userId: uid,
        geschaeftsfallId: 'rechnung_storniert',
        bezeichnung: 'Rechnung storniert (Nettobetrag)',
        sollKonto: 3000,
        habenKonto: 1100,
        autoTrigger: 'rechnung_storniert',
      ),
      BuchungsVorlage(
        id: 'default_rechnung_storniert_mwst',
        userId: uid,
        geschaeftsfallId: 'rechnung_storniert_mwst',
        bezeichnung: 'Rechnung storniert (MWST-Anteil)',
        sollKonto: 2200,
        habenKonto: 1100,
        autoTrigger: 'rechnung_storniert',
      ),
      // ── Manuelle Vorlagen ──
      BuchungsVorlage(
        id: 'default_materialeinkauf_bar',
        userId: uid,
        geschaeftsfallId: 'materialeinkauf_bar',
        bezeichnung: 'Materialeinkauf bar bezahlt',
        sollKonto: 4000,
        habenKonto: 1000,
      ),
      BuchungsVorlage(
        id: 'default_materialeinkauf_rechnung',
        userId: uid,
        geschaeftsfallId: 'materialeinkauf_rechnung',
        bezeichnung: 'Materialeinkauf auf Rechnung',
        sollKonto: 4000,
        habenKonto: 2000,
      ),
      BuchungsVorlage(
        id: 'default_vorsteuer_einkauf',
        userId: uid,
        geschaeftsfallId: 'vorsteuer_einkauf',
        bezeichnung: 'Vorsteuer auf Einkauf',
        sollKonto: 1170,
        habenKonto: 2000,
      ),
      BuchungsVorlage(
        id: 'default_kreditor_bezahlt',
        userId: uid,
        geschaeftsfallId: 'kreditor_bezahlt',
        bezeichnung: 'Lieferantenrechnung bezahlt',
        sollKonto: 2000,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_lohn_zahlung',
        userId: uid,
        geschaeftsfallId: 'lohn_zahlung',
        bezeichnung: 'Lohnzahlung Mitarbeiter',
        sollKonto: 5000,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_sozialversicherung',
        userId: uid,
        geschaeftsfallId: 'sozialversicherung',
        bezeichnung: 'AHV/IV/EO Arbeitgeberanteil',
        sollKonto: 5700,
        habenKonto: 2270,
      ),
      BuchungsVorlage(
        id: 'default_miete_zahlung',
        userId: uid,
        geschaeftsfallId: 'miete_zahlung',
        bezeichnung: 'Miete Werkstatt / Buero',
        sollKonto: 6000,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_treibstoff',
        userId: uid,
        geschaeftsfallId: 'treibstoff',
        bezeichnung: 'Treibstoff Firmenfahrzeug',
        sollKonto: 6210,
        habenKonto: 1000,
      ),
      BuchungsVorlage(
        id: 'default_versicherung',
        userId: uid,
        geschaeftsfallId: 'versicherung',
        bezeichnung: 'Versicherungspraemie',
        sollKonto: 6300,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_telefon_internet',
        userId: uid,
        geschaeftsfallId: 'telefon_internet',
        bezeichnung: 'Telefon / Internet',
        sollKonto: 6510,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_fremdleistung',
        userId: uid,
        geschaeftsfallId: 'fremdleistung',
        bezeichnung: 'Fremdleistung / Subunternehmer',
        sollKonto: 4200,
        habenKonto: 2000,
      ),
      BuchungsVorlage(
        id: 'default_bankgebuehren',
        userId: uid,
        geschaeftsfallId: 'bankgebuehren',
        bezeichnung: 'Bankgebuehren und Spesen',
        sollKonto: 6900,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_mwst_zahlung',
        userId: uid,
        geschaeftsfallId: 'mwst_zahlung',
        bezeichnung: 'MWST-Zahlung ans Steueramt',
        sollKonto: 2200,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_inhaberlohn',
        userId: uid,
        geschaeftsfallId: 'inhaberlohn',
        bezeichnung: 'Lohn Geschaeftsfuehrer/Inhaber',
        sollKonto: 5200,
        habenKonto: 1020,
      ),
      BuchungsVorlage(
        id: 'default_abschreibung_maschinen',
        userId: uid,
        geschaeftsfallId: 'abschreibung_maschinen',
        bezeichnung: 'Abschreibung Maschinen/Werkzeuge',
        sollKonto: 6820,
        habenKonto: 1500,
      ),
      BuchungsVorlage(
        id: 'default_abschreibung_fahrzeuge',
        userId: uid,
        geschaeftsfallId: 'abschreibung_fahrzeuge',
        bezeichnung: 'Abschreibung Fahrzeuge',
        sollKonto: 6810,
        habenKonto: 1520,
      ),
      BuchungsVorlage(
        id: 'default_bareinzahlung_bank',
        userId: uid,
        geschaeftsfallId: 'bareinzahlung_bank',
        bezeichnung: 'Bareinzahlung auf Bank',
        sollKonto: 1020,
        habenKonto: 1000,
      ),
      BuchungsVorlage(
        id: 'default_barbezug',
        userId: uid,
        geschaeftsfallId: 'barbezug',
        bezeichnung: 'Barbezug vom Bankkonto',
        sollKonto: 1000,
        habenKonto: 1020,
      ),
    ];
  }
}
