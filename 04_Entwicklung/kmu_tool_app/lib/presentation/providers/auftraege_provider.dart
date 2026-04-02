/// Auftraege providers using simple FutureProvider pattern.
///
/// For screens that need `.notifier.refresh()`, use the AsyncNotifier-based
/// providers from `providers.dart` instead. These providers are useful for
/// read-only views and widgets that can use `ref.invalidate()` to refresh.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_repository.dart';

/// Simple FutureProvider for the Auftraege list.
final auftraegeFutureProvider =
    FutureProvider<List<AuftragLocal>>((ref) async {
  return AuftragRepository.getAll();
});

/// Simple FutureProvider for a single Auftrag by ID.
final auftragFutureProvider =
    FutureProvider.family<AuftragLocal?, String>((ref, id) async {
  return AuftragRepository.getById(id);
});

/// Provides all Auftraege for a given Kunde.
final auftraegeByKundeFutureProvider =
    FutureProvider.family<List<AuftragLocal>, String>((ref, kundeId) async {
  return AuftragRepository.getByKunde(kundeId);
});

/// Provides Auftraege filtered by status (e.g. 'offen', 'in_bearbeitung', 'abgeschlossen').
final auftraegeByStatusProvider =
    FutureProvider.family<List<AuftragLocal>, String>((ref, status) async {
  return AuftragRepository.getByStatus(status);
});

/// Provides all Auftraege linked to a given Offerte.
final auftraegeByOfferteFutureProvider =
    FutureProvider.family<List<AuftragLocal>, String>((ref, offerteId) async {
  return AuftragRepository.getByOfferte(offerteId);
});

/// Provides the count of Auftraege.
final auftraegeCountProvider = FutureProvider<int>((ref) async {
  return AuftragRepository.count();
});
