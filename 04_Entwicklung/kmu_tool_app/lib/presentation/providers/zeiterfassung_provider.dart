/// Zeiterfassung providers using simple FutureProvider pattern.
///
/// For screens that need `.notifier.refresh()`, use the AsyncNotifier-based
/// `zeiterfassungenByAuftragProvider` from `providers.dart` instead.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/local/zeiterfassung_local_export.dart';
import 'package:kmu_tool_app/data/repositories/zeiterfassung_repository.dart';

/// Simple FutureProvider for Zeiterfassungen by Auftrag.
final zeiterfassungenByAuftragFutureProvider = FutureProvider.family<
    List<ZeiterfassungLocal>, String>((ref, auftragId) async {
  return ZeiterfassungRepository.getByAuftrag(auftragId);
});

/// Provides a single Zeiterfassung by its local/server ID.
final zeiterfassungFutureProvider =
    FutureProvider.family<ZeiterfassungLocal?, String>((ref, id) async {
  return ZeiterfassungRepository.getById(id);
});

/// Provides all Zeiterfassungen (across all Auftraege).
final zeiterfassungenAllProvider =
    FutureProvider<List<ZeiterfassungLocal>>((ref) async {
  return ZeiterfassungRepository.getAll();
});

/// Provides the total count of Zeiterfassungen.
final zeiterfassungenCountProvider = FutureProvider<int>((ref) async {
  return ZeiterfassungRepository.count();
});
