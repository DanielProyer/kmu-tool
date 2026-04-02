import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/core/config/features.dart';
import 'package:kmu_tool_app/services/feature/feature_service.dart';

/// Provider: Prüft ob ein bestimmtes Feature aktiv ist.
final hasFeatureProvider = Provider.family<bool, AppFeature>((ref, feature) {
  return FeatureService.instance.hasFeature(feature);
});

/// Provider: Aktueller Plan-Name.
final currentPlanNameProvider = Provider<String>((ref) {
  return FeatureService.instance.currentPlan?.bezeichnung ?? 'Gratis';
});

/// Provider: Aktueller Plan-ID.
final currentPlanIdProvider = Provider<String>((ref) {
  return FeatureService.instance.currentPlan?.id ?? 'free';
});
