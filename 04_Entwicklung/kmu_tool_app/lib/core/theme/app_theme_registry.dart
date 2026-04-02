import 'app_theme_config.dart';

/// Statisches Register aller verfügbaren Themes.
/// Designer fügt neue Themes hinzu via [register].
class AppThemeRegistry {
  static final Map<String, AppThemeConfig> _themes = {};

  /// Registriert ein Theme. Wird beim App-Start aufgerufen.
  static void register(AppThemeConfig config) {
    _themes[config.id] = config;
  }

  /// Gibt ein Theme zurück (Fallback: erstes registrierte).
  static AppThemeConfig get(String id) {
    return _themes[id] ?? _themes.values.first;
  }

  /// Alle registrierten Themes (sortiert nach Registrierungsreihenfolge).
  static List<AppThemeConfig> get all => _themes.values.toList();

  /// Default-Theme-ID.
  static String get defaultId => 'blau_orange';

  /// Initialisiert alle mitgelieferten Themes.
  static void initialize(List<AppThemeConfig> configs) {
    for (final config in configs) {
      register(config);
    }
  }
}
