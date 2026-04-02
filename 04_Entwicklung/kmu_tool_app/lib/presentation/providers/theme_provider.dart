import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/core/theme/app_theme_config.dart';
import 'package:kmu_tool_app/core/theme/app_theme_registry.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

/// Aktuell gewählte Theme-Config. Reactive – UI rebuilt bei Änderung.
final themeConfigProvider =
    StateNotifierProvider<ThemeConfigNotifier, AppThemeConfig>((ref) {
  return ThemeConfigNotifier();
});

class ThemeConfigNotifier extends StateNotifier<AppThemeConfig> {
  ThemeConfigNotifier()
      : super(AppThemeRegistry.get(AppThemeRegistry.defaultId));

  /// Lädt Theme-ID aus user_profiles.
  Future<void> loadFromProfile() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await SupabaseService.client
          .from('user_profiles')
          .select('theme_id')
          .eq('id', userId)
          .maybeSingle();

      if (response != null && response['theme_id'] != null) {
        state = AppThemeRegistry.get(response['theme_id'] as String);
      }
    } catch (_) {
      // Fallback: Default-Theme bleibt
    }
  }

  /// Wechselt Theme und speichert in Supabase.
  Future<void> setTheme(String themeId) async {
    state = AppThemeRegistry.get(themeId);

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseService.client
          .from('user_profiles')
          .update({'theme_id': themeId}).eq('id', userId);
    } catch (_) {
      // Theme bleibt trotzdem lokal gesetzt
    }
  }
}
