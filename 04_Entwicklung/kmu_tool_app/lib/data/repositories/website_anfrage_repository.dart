import 'package:kmu_tool_app/data/models/website_anfrage.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class WebsiteAnfrageRepository {
  static Future<List<WebsiteAnfrage>> getByConfig(
    String configId, {
    bool unreadOnly = false,
  }) async {
    try {
      var query = SupabaseService.client
          .from('website_anfragen')
          .select()
          .eq('config_id', configId);
      if (unreadOnly) {
        query = query.eq('gelesen', false);
      }
      final rows = await query.order('created_at', ascending: false);
      return rows.map((r) => WebsiteAnfrage.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> markAsRead(String id) async {
    await SupabaseService.client
        .from('website_anfragen')
        .update({'gelesen': true}).eq('id', id);
  }

  static Future<int> getUnreadCount(String configId) async {
    try {
      final rows = await SupabaseService.client
          .from('website_anfragen')
          .select('id')
          .eq('config_id', configId)
          .eq('gelesen', false);
      return rows.length;
    } catch (_) {
      return 0;
    }
  }
}
