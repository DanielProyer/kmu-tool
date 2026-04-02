import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kmu_tool_app/app.dart';
import 'package:kmu_tool_app/core/theme/app_theme_registry.dart';
import 'package:kmu_tool_app/core/theme/themes/blau_orange_theme.dart';
import 'package:kmu_tool_app/core/theme/themes/gruen_braun_theme.dart';
import 'package:kmu_tool_app/core/theme/themes/anthrazit_gold_theme.dart';
import 'package:kmu_tool_app/core/theme/themes/rot_grau_theme.dart';
import 'package:kmu_tool_app/core/theme/themes/dunkel_theme.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/connectivity/connectivity_service.dart';
import 'package:kmu_tool_app/services/sync/sync_service_export.dart';
import 'package:kmu_tool_app/services/feature/feature_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('de_CH');

  // Theme-Registry initialisieren
  AppThemeRegistry.initialize([
    blauOrangeTheme,
    gruenBraunTheme,
    anthrazitGoldTheme,
    rotGrauTheme,
    dunkelTheme,
  ]);

  await dotenv.load(fileName: '.env');
  await SupabaseService.initialize();

  // Früh auf Recovery-Event lauschen (bevor runApp)
  SupabaseService.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      SupabaseService.pendingPasswordRecovery = true;
    }
  });

  // Session refreshen (Web + Native)
  if (SupabaseService.isAuthenticated) {
    try {
      await SupabaseService.client.auth.refreshSession();
    } catch (_) {
      await SupabaseService.client.auth.signOut();
    }

    // Feature-Service laden (nach Auth)
    await FeatureService.instance.load();
  }

  // Connectivity auf allen Plattformen initialisieren
  await ConnectivityService.initialize();

  if (!kIsWeb) {
    await IsarService.initialize();

    if (SupabaseService.isAuthenticated) {
      SyncService.startListening();
      if (ConnectivityService.isOnline) {
        SyncService.syncAll();
      }
    }
  }

  runApp(
    const ProviderScope(
      child: KmuToolApp(),
    ),
  );
}
