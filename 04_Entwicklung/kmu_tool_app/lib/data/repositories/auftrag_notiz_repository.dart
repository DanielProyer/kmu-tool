import 'package:kmu_tool_app/data/models/auftrag_notiz.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

/// Supabase-only Repository (kein Offline-Support).
class AuftragNotizRepository {
  static Future<List<AuftragNotiz>> getByAuftrag(String auftragId) async {
    final response = await SupabaseService.client
        .from('auftrag_notizen')
        .select()
        .eq('auftrag_id', auftragId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => AuftragNotiz.fromJson(json))
        .toList();
  }

  static Future<AuftragNotiz> create(AuftragNotiz notiz) async {
    final response = await SupabaseService.client
        .from('auftrag_notizen')
        .insert(notiz.toJson())
        .select()
        .single();

    return AuftragNotiz.fromJson(response);
  }

  static Future<void> update(String id, Map<String, dynamic> data) async {
    await SupabaseService.client
        .from('auftrag_notizen')
        .update(data)
        .eq('id', id);
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client
        .from('auftrag_notizen')
        .delete()
        .eq('id', id);
  }
}
