import 'package:kmu_tool_app/data/models/auftrag_datei.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

/// Supabase-only Repository (kein Offline-Support).
class AuftragDateiRepository {
  static Future<List<AuftragDatei>> getByAuftrag(String auftragId) async {
    final response = await SupabaseService.client
        .from('auftrag_dateien')
        .select()
        .eq('auftrag_id', auftragId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AuftragDatei.fromJson(json))
        .toList();
  }

  static Future<AuftragDatei> create(AuftragDatei datei) async {
    final response = await SupabaseService.client
        .from('auftrag_dateien')
        .insert(datei.toJson())
        .select()
        .single();

    return AuftragDatei.fromJson(response);
  }

  static Future<void> update(String id, Map<String, dynamic> data) async {
    await SupabaseService.client
        .from('auftrag_dateien')
        .update(data)
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client
        .from('auftrag_dateien')
        .delete()
        .eq('id', id);
  }
}
