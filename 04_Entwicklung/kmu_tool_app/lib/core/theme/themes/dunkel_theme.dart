import 'package:flutter/material.dart';
import '../app_theme_config.dart';

/// Dark Mode: Dunkle Oberflächen + blaue Akzente.
const dunkelTheme = AppThemeConfig(
  id: 'dunkel',
  name: 'Dunkel',
  primary: Color(0xFF60A5FA),
  secondary: Color(0xFFFBBF24),
  surface: Color(0xFF1A1A2E),
  surfaceCard: Color(0xFF16213E),
  textPrimary: Color(0xFFF1F5F9),
  textSecondary: Color(0xFF94A3B8),
  divider: Color(0xFF334155),
  brightness: Brightness.dark,
);
