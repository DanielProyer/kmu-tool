import 'package:kmu_tool_app/data/models/auftrag_zugriff.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

/// Supabase-only Repository (kein Offline-Support).
class AuftragZugriffRepository {
  static Future<List<AuftragZugriff>> getByAuftrag(String auftragId) async {
    final response = await SupabaseService.client
        .from('auftrag_zugriffe')
        .select()
        .eq('auftrag_id', auftragId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AuftragZugriff.fromJson(json))
        .toList();
  }

  static Future<AuftragZugriff> create(AuftragZugriff zugriff) async {
    final response = await SupabaseService.client
        .from('auftrag_zugriffe')
        .insert(zugriff.toJson())
        .select()
        .single();

    return AuftragZugriff.fromJson(response);
  }

  static Future<void> updateRolle(String id, String rolle) async {
    await SupabaseService.client
        .from('auftrag_zugriffe')
        .update({'rolle': rolle}).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client
        .from('auftrag_zugriffe')
        .delete()
        .eq('id', id);
  }
}
