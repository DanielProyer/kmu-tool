import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class WebsiteSectionRepository {
  static Future<List<WebsiteSection>> getByConfig(String configId) async {
    try {
      final rows = await SupabaseService.client
          .from('website_sections')
          .select()
          .eq('config_id', configId)
          .order('sortierung');
      return rows.map((r) => WebsiteSection.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<WebsiteSection> save(WebsiteSection section) async {
    final json = section.toJson();
    final rows = await SupabaseService.client
        .from('website_sections')
        .upsert(json)
        .select();
    return WebsiteSection.fromJson(rows.first);
  }

  static Future<void> updateSortierung(List<WebsiteSection> sections) async {
    for (var i = 0; i < sections.length; i++) {
      await SupabaseService.client
          .from('website_sections')
          .update({'sortierung': i}).eq('id', sections[i].id);
    }
  }

  static Future<void> updateVisibility(String id, bool visible) async {
    await SupabaseService.client
        .from('website_sections')
        .update({'is_visible': visible}).eq('id', id);
  }
}
