/// Kunden providers using simple FutureProvider pattern.
///
/// For screens that need `.notifier.refresh()`, use the AsyncNotifier-based
/// providers from `providers.dart` instead. These providers are useful for
/// read-only views and widgets that can use `ref.invalidate()` to refresh.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';

/// Simple FutureProvider for the Kunden list.
/// Use `ref.invalidate(kundenFutureProvider)` to refresh.
final kundenFutureProvider = FutureProvider<List<KundeLocal>>((ref) async {
  return KundeRepository.getAll();
});

/// Simple FutureProvider for a single Kunde by ID.
/// Use `ref.invalidate(kundeFutureProvider(id))` to refresh.
final kundeFutureProvider =
    FutureProvider.family<KundeLocal?, String>((ref, id) async {
  return KundeRepository.getById(id);
});

/// Provides the total count of active Kunden.
final kundenCountProvider = FutureProvider<int>((ref) async {
  return KundeRepository.count();
});
