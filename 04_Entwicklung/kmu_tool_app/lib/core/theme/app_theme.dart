import 'package:flutter/material.dart';
import 'app_theme_config.dart';

/// Semantische Status-Farben – GLOBAL, theme-unabhängig.
class AppStatusColors {
  // Status
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF2563EB);

  // Sync
  static const online = Color(0xFF16A34A);
  static const offline = Color(0xFFEF4444);
  static const syncing = Color(0xFF3B82F6);

  // Auftrags-Status
  static const offen = Color(0xFF3B82F6);
  static const inBearbeitung = Color(0xFFF59E0B);
  static const abgeschlossen = Color(0xFF16A34A);
  static const storniert = Color(0xFF9CA3AF);
}

/// Baut ThemeData aus einer [AppThemeConfig].
class AppTheme {
  /// Legacy-Zugang für bestehenden Code.
  static ThemeData get light => fromConfig(
        const AppThemeConfig(
          id: 'blau_orange',
          name: 'Blau & Orange',
          primary: Color(0xFF2563EB),
          secondary: Color(0xFFF97316),
        ),
      );

  /// Erzeugt ThemeData aus einer Config.
  static ThemeData fromConfig(AppThemeConfig config) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: config.primary,
      secondary: config.secondary,
      brightness: config.brightness,
      surface: config.surface,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      brightness: config.brightness,

      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: config.surface,
        foregroundColor: config.textPrimary,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: config.textPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: config.divider),
        ),
        color: config.surfaceCard,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: config.surfaceCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: config.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: config.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          side: BorderSide(color: config.divider),
        ),
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: config.divider,
        thickness: 1,
        space: 1,
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: config.brightness == Brightness.dark
            ? Colors.black
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // SearchBar
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(config.surfaceCard),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: config.divider),
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
