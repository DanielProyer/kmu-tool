import 'package:kmu_tool_app/data/models/website_gallery_image.dart';
import 'package:kmu_tool_app/services/storage/file_storage_service.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class WebsiteGalleryRepository {
  static Future<List<WebsiteGalleryImage>> getByConfig(
      String configId) async {
    try {
      final rows = await SupabaseService.client
          .from('website_gallery_images')
          .select()
          .eq('config_id', configId)
          .order('sortierung');
      return rows.map((r) => WebsiteGalleryImage.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<WebsiteGalleryImage> create(
      WebsiteGalleryImage image) async {
    final rows = await SupabaseService.client
        .from('website_gallery_images')
        .insert(image.toJson())
        .select();
    return WebsiteGalleryImage.fromJson(rows.first);
  }

  static Future<void> delete(String id) async {
    // Erst Storage-Pfad holen, dann loeschen
    final rows = await SupabaseService.client
        .from('website_gallery_images')
        .select('storage_path')
        .eq('id', id)
        .limit(1);
    if (rows.isNotEmpty) {
      final path = rows.first['storage_path'] as String;
      await FileStorageService.deleteWebsiteAsset(path);
    }
    await SupabaseService.client
        .from('website_gallery_images')
        .delete()
        .eq('id', id);
  }

  static Future<void> updateSortierung(
      List<WebsiteGalleryImage> images) async {
    for (var i = 0; i < images.length; i++) {
      await SupabaseService.client
          .from('website_gallery_images')
          .update({'sortierung': i}).eq('id', images[i].id);
    }
  }
}
