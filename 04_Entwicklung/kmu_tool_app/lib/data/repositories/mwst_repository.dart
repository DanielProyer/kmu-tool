import 'package:kmu_tool_app/data/models/mwst_code.dart';
import 'package:kmu_tool_app/data/models/mwst_einstellung.dart';
import 'package:kmu_tool_app/data/models/mwst_abrechnung.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class MwstRepository {
  String get _userId => SupabaseService.currentUser!.id;

  // ─── MWST-Codes (systemweit) ───

  Future<List<MwstCode>> getCodes() async {
    final data = await SupabaseService.client
        .from('mwst_codes')
        .select()
        .eq('ist_aktiv', true)
        .order('code');
    return data.map((json) => MwstCode.fromJson(json)).toList();
  }

  Future<MwstCode?> getCodeByCode(String code) async {
    final data = await SupabaseService.client
        .from('mwst_codes')
        .select()
        .eq('code', code)
        .eq('ist_aktiv', true)
        .maybeSingle();
    return data != null ? MwstCode.fromJson(data) : null;
  }

  /// Gibt nur Umsatzsteuer-Codes zurueck (fuer Ausgangsrechnungen)
  Future<List<MwstCode>> getUmsatzsteuerCodes() async {
    final data = await SupabaseService.client
        .from('mwst_codes')
        .select()
        .eq('ist_aktiv', true)
        .eq('typ', 'umsatzsteuer')
        .order('code');
    return data.map((json) => MwstCode.fromJson(json)).toList();
  }

  /// Gibt nur Vorsteuer-Codes zurueck (fuer Eingangsrechnungen)
  Future<List<MwstCode>> getVorsteuerCodes() async {
    final data = await SupabaseService.client
        .from('mwst_codes')
        .select()
        .eq('ist_aktiv', true)
        .inFilter('typ', ['vorsteuer', 'bezugsteuer', 'ohne'])
        .order('code');
    return data.map((json) => MwstCode.fromJson(json)).toList();
  }

  // ─── MWST-Einstellungen (pro User) ───

  Future<MwstEinstellung?> getEinstellung() async {
    final data = await SupabaseService.client
        .from('mwst_einstellungen')
        .select()
        .eq('user_id', _userId)
        .maybeSingle();
    return data != null ? MwstEinstellung.fromJson(data) : null;
  }

  Future<void> saveEinstellung(MwstEinstellung einstellung) async {
    await SupabaseService.client
        .from('mwst_einstellungen')
        .upsert(einstellung.toJson());
  }

  // ─── MWST-Abrechnungen ───

  Future<List<MwstAbrechnung>> getAbrechnungen() async {
    final data = await SupabaseService.client
        .from('mwst_abrechnungen')
        .select()
        .eq('user_id', _userId)
        .order('periode_start', ascending: false);
    return data.map((json) => MwstAbrechnung.fromJson(json)).toList();
  }

  Future<MwstAbrechnung?> getAbrechnung(String id) async {
    final data = await SupabaseService.client
        .from('mwst_abrechnungen')
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return data != null ? MwstAbrechnung.fromJson(data) : null;
  }

  Future<void> saveAbrechnung(MwstAbrechnung abrechnung) async {
    await SupabaseService.client
        .from('mwst_abrechnungen')
        .upsert(abrechnung.toJson());
  }

  Future<void> updateAbrechnungStatus(String id, String status) async {
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
        .eq('user_id', _userId);
  }

  Future<void> deleteAbrechnung(String id) async {
    await SupabaseService.client
        .from('mwst_abrechnungen')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
