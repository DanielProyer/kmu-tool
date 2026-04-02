/// Offerten providers using simple FutureProvider pattern.
///
/// For screens that need `.notifier.refresh()`, use the AsyncNotifier-based
/// providers from `providers.dart` instead. These providers are useful for
/// read-only views and widgets that can use `ref.invalidate()` to refresh.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/repositories/offerte_repository.dart';

/// Simple FutureProvider for the Offerten list.
final offertenFutureProvider =
    FutureProvider<List<OfferteLocal>>((ref) async {
  return OfferteRepository.getAll();
});

/// Simple FutureProvider for a single Offerte by ID.
final offerteFutureProvider =
    FutureProvider.family<OfferteLocal?, String>((ref, id) async {
  return OfferteRepository.getById(id);
});

/// Provides all Offerten for a given Kunde.
final offertenByKundeFutureProvider =
    FutureProvider.family<List<OfferteLocal>, String>((ref, kundeId) async {
  return OfferteRepository.getByKunde(kundeId);
});

/// Provides Offerten filtered by status (e.g. 'offen', 'angenommen', 'abgelehnt').
final offertenByStatusProvider =
    FutureProvider.family<List<OfferteLocal>, String>((ref, status) async {
  return OfferteRepository.getByStatus(status);
});

/// Provides the count of Offerten.
final offertenCountProvider = FutureProvider<int>((ref) async {
  return OfferteRepository.count();
});
