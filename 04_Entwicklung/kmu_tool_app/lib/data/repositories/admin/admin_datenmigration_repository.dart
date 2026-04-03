import '../../../services/supabase/supabase_service.dart';
import '../../models/admin/admin_datenmigration.dart';

class AdminDatenmigrationRepository {
  static const _table = 'admin_datenmigrationen';

  static Future<List<AdminDatenmigration>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, admin_kundenprofile(firma_name)')
        .order('created_at', ascending: false);
    return data.map((json) => AdminDatenmigration.fromJson(json)).toList();
  }

  static Future<List<AdminDatenmigration>> getByKunde(
      String kundeProfilId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, admin_kundenprofile(firma_name)')
        .eq('kunde_profil_id', kundeProfilId)
        .order('created_at', ascending: false);
    return data.map((json) => AdminDatenmigration.fromJson(json)).toList();
  }

  static Future<void> save(AdminDatenmigration migration) async {
    await SupabaseService.client.from(_table).upsert(migration.toJson());
  }

  static Future<void> updateStatus(String id, String status,
      {int? fortschritt, String? ergebnis}) async {
    final update = <String, dynamic>{'status': status};
    if (fortschritt != null) update['fortschritt'] = fortschritt;
    if (ergebnis != null) update['ergebnis_zusammenfassung'] = ergebnis;
    await SupabaseService.client.from(_table).update(update).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }
}
