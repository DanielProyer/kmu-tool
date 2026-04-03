import '../../../services/supabase/supabase_service.dart';
import '../../models/admin/admin_rechnung.dart';

class AdminRechnungRepository {
  static const _table = 'admin_rechnungen';

  static Future<List<AdminRechnung>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, admin_kundenprofile(firma_name)')
        .order('created_at', ascending: false);
    return data.map((json) => AdminRechnung.fromJson(json)).toList();
  }

  static Future<List<AdminRechnung>> getByStatus(String status) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, admin_kundenprofile(firma_name)')
        .eq('status', status)
        .order('created_at', ascending: false);
    return data.map((json) => AdminRechnung.fromJson(json)).toList();
  }

  static Future<List<AdminRechnung>> getByKunde(String kundeProfilId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, admin_kundenprofile(firma_name)')
        .eq('kunde_profil_id', kundeProfilId)
        .order('created_at', ascending: false);
    return data.map((json) => AdminRechnung.fromJson(json)).toList();
  }

  static Future<AdminRechnung?> getById(String id) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, admin_kundenprofile(firma_name)')
        .eq('id', id)
        .maybeSingle();
    return data != null ? AdminRechnung.fromJson(data) : null;
  }

  static Future<void> save(AdminRechnung rechnung) async {
    await SupabaseService.client.from(_table).upsert(rechnung.toJson());
  }

  static Future<void> updateStatus(String id, String status,
      {DateTime? bezahltAm}) async {
    final update = <String, dynamic>{'status': status};
    if (bezahltAm != null) {
      update['bezahlt_am'] = bezahltAm.toIso8601String();
    }
    await SupabaseService.client.from(_table).update(update).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  static Future<String> nextRechnungsNr() async {
    final now = DateTime.now();
    final prefix = 'ADM-${now.year}-';
    final data = await SupabaseService.client
        .from(_table)
        .select('rechnungs_nr')
        .like('rechnungs_nr', '$prefix%')
        .order('rechnungs_nr', ascending: false)
        .limit(1);
    if (data.isEmpty) return '${prefix}001';
    final last = data.first['rechnungs_nr'] as String;
    final nr = int.tryParse(last.split('-').last) ?? 0;
    return '$prefix${(nr + 1).toString().padLeft(3, '0')}';
  }
}
