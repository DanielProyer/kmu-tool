import 'package:kmu_tool_app/data/models/mwst_code.dart';
import 'package:kmu_tool_app/data/models/mwst_einstellung.dart';
import 'package:kmu_tool_app/data/models/mwst_abrechnung.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';

class MwstRepository {
  // --- MWST-Codes (systemweit) ---

  Future<List<MwstCode>> getCodes() async {
    try {
      final data = await SupabaseService.client
          .from('mwst_codes')
          .select()
          .eq('ist_aktiv', true)
          .order('code');
      return data.map((json) => MwstCode.fromJson(json)).toList();
    } catch (_) {
      return _defaultMwstCodes();
    }
  }

  Future<MwstCode?> getCodeByCode(String code) async {
    try {
      final data = await SupabaseService.client
          .from('mwst_codes')
          .select()
          .eq('code', code)
          .eq('ist_aktiv', true)
          .maybeSingle();
      return data != null ? MwstCode.fromJson(data) : null;
    } catch (_) {
      return _defaultMwstCodes()
          .where((c) => c.code == code)
          .firstOrNull;
    }
  }

  /// Gibt nur Umsatzsteuer-Codes zurueck (fuer Ausgangsrechnungen)
  Future<List<MwstCode>> getUmsatzsteuerCodes() async {
    try {
      final data = await SupabaseService.client
          .from('mwst_codes')
          .select()
          .eq('ist_aktiv', true)
          .eq('typ', 'umsatzsteuer')
          .order('code');
      return data.map((json) => MwstCode.fromJson(json)).toList();
    } catch (_) {
      return _defaultMwstCodes()
          .where((c) => c.typ == 'umsatzsteuer')
          .toList();
    }
  }

  /// Gibt nur Vorsteuer-Codes zurueck (fuer Eingangsrechnungen)
  Future<List<MwstCode>> getVorsteuerCodes() async {
    try {
      final data = await SupabaseService.client
          .from('mwst_codes')
          .select()
          .eq('ist_aktiv', true)
          .inFilter('typ', ['vorsteuer', 'bezugsteuer', 'ohne'])
          .order('code');
      return data.map((json) => MwstCode.fromJson(json)).toList();
    } catch (_) {
      return _defaultMwstCodes()
          .where((c) =>
              c.typ == 'vorsteuer' ||
              c.typ == 'bezugsteuer' ||
              c.typ == 'ohne')
          .toList();
    }
  }

  // --- MWST-Einstellungen (pro User) ---

  Future<MwstEinstellung?> getEinstellung() async {
    try {
      final userId = await BetriebService.getDataOwnerId();
      final data = await SupabaseService.client
          .from('mwst_einstellungen')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data != null ? MwstEinstellung.fromJson(data) : null;
    } catch (_) {
      return null; // Tabelle existiert noch nicht
    }
  }

  Future<void> saveEinstellung(MwstEinstellung einstellung) async {
    try {
      await SupabaseService.client
          .from('mwst_einstellungen')
          .upsert(einstellung.toJson());
    } catch (_) {
      // Tabelle existiert noch nicht
    }
  }

  // --- MWST-Abrechnungen ---

  Future<List<MwstAbrechnung>> getAbrechnungen() async {
    try {
      final userId = await BetriebService.getDataOwnerId();
      final data = await SupabaseService.client
          .from('mwst_abrechnungen')
          .select()
          .eq('user_id', userId)
          .order('periode_start', ascending: false);
      return data.map((json) => MwstAbrechnung.fromJson(json)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<MwstAbrechnung?> getAbrechnung(String id) async {
    try {
      final userId = await BetriebService.getDataOwnerId();
      final data = await SupabaseService.client
          .from('mwst_abrechnungen')
          .select()
          .eq('id', id)
          .eq('user_id', userId)
          .maybeSingle();
      return data != null ? MwstAbrechnung.fromJson(data) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveAbrechnung(MwstAbrechnung abrechnung) async {
    try {
      await SupabaseService.client
          .from('mwst_abrechnungen')
          .upsert(abrechnung.toJson());
    } catch (_) {
      // Tabelle existiert noch nicht
    }
  }

  Future<void> updateAbrechnungStatus(String id, String status) async {
    try {
      final userId = await BetriebService.getDataOwnerId();
      final updates = <String, dynamic>{'status': status};
      if (status == 'eingereicht') {
        updates['eingereicht_am'] = DateTime.now().toIso8601String();
      } else if (status == 'bezahlt') {
        updates['bezahlt_am'] = DateTime.now().toIso8601String();
      }
      await SupabaseService.client
          .from('mwst_abrechnungen')
          .update(updates)
          .eq('id', id)
          .eq('user_id', userId);
    } catch (_) {
      // Tabelle existiert noch nicht
    }
  }

  Future<void> deleteAbrechnung(String id) async {
    try {
      final userId = await BetriebService.getDataOwnerId();
      await SupabaseService.client
          .from('mwst_abrechnungen')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
    } catch (_) {
      // Tabelle existiert noch nicht
    }
  }

  /// Hardcoded Standard-MWST-Codes als Fallback (Schweiz 2024+)
  List<MwstCode> _defaultMwstCodes() {
    final ab = DateTime(2024, 1, 1);
    return [
      MwstCode(id: 'def_ohne', code: 'OHNE', bezeichnung: 'Ohne MWST', satz: 0.0, typ: 'ohne', gueltigAb: ab),
      MwstCode(id: 'def_ust81', code: 'UST81', bezeichnung: 'Umsatzsteuer 8.1%', satz: 8.1, typ: 'umsatzsteuer', gueltigAb: ab),
      MwstCode(id: 'def_ust26', code: 'UST26', bezeichnung: 'Umsatzsteuer 2.6%', satz: 2.6, typ: 'umsatzsteuer', gueltigAb: ab),
      MwstCode(id: 'def_ust38', code: 'UST38', bezeichnung: 'Umsatzsteuer 3.8%', satz: 3.8, typ: 'umsatzsteuer', gueltigAb: ab),
      MwstCode(id: 'def_vst81', code: 'VST81', bezeichnung: 'Vorsteuer 8.1%', satz: 8.1, typ: 'vorsteuer', gueltigAb: ab),
      MwstCode(id: 'def_vst26', code: 'VST26', bezeichnung: 'Vorsteuer 2.6%', satz: 2.6, typ: 'vorsteuer', gueltigAb: ab),
      MwstCode(id: 'def_vst38', code: 'VST38', bezeichnung: 'Vorsteuer 3.8%', satz: 3.8, typ: 'vorsteuer', gueltigAb: ab),
    ];
  }
}
