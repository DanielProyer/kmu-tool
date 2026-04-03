import 'package:kmu_tool_app/data/models/website_config.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';

class WebsiteConfigRepository {
  static Future<WebsiteConfig?> getByCurrentUser() async {
    try {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('website_configs')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false)
          .limit(1);
      if (rows.isEmpty) return null;
      return WebsiteConfig.fromJson(rows.first);
    } catch (_) {
      return null;
    }
  }

  static Future<WebsiteConfig> save(WebsiteConfig config) async {
    final json = config.toJson();
    final rows = await SupabaseService.client
        .from('website_configs')
        .upsert(json)
        .select();
    return WebsiteConfig.fromJson(rows.first);
  }

  static Future<void> updatePublished(String id, bool published) async {
    await SupabaseService.client
        .from('website_configs')
        .update({'is_published': published}).eq('id', id);
  }

  static Future<bool> isSlugAvailable(String slug, {String? excludeId}) async {
    try {
      var query = SupabaseService.client
          .from('website_configs')
          .select('id')
          .eq('slug', slug);
      if (excludeId != null) {
        query = query.neq('id', excludeId);
      }
      final rows = await query.limit(1);
      return rows.isEmpty;
    } catch (_) {
      return false;
    }
  }
}
