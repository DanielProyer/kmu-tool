import 'package:flutter/material.dart';

/// Reine Farb-/Stil-Definitionen für ein Theme.
/// Designer fügt nur neue Config hinzu – kein ThemeData-Wissen nötig.
class AppThemeConfig {
  final String id;
  final String name;
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color surfaceCard;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Brightness brightness;

  const AppThemeConfig({
    required this.id,
    required this.name,
    required this.primary,
    required this.secondary,
    this.surface = const Color(0xFFF8F9FA),
    this.surfaceCard = Colors.white,
    this.textPrimary = const Color(0xFF1A1A1A),
    this.textSecondary = const Color(0xFF6B7280),
    this.divider = const Color(0xFFE5E7EB),
    this.brightness = Brightness.light,
  });
}
