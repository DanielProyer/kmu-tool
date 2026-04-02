/// Rapporte providers using simple FutureProvider pattern.
///
/// For screens that need `.notifier.refresh()`, use the AsyncNotifier-based
/// `rapporteByAuftragProvider` from `providers.dart` instead.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/local/rapport_local_export.dart';
import 'package:kmu_tool_app/data/repositories/rapport_repository.dart';

/// Simple FutureProvider for Rapporte by Auftrag.
final rapporteByAuftragFutureProvider =
    FutureProvider.family<List<RapportLocal>, String>((ref, auftragId) async {
  return RapportRepository.getByAuftrag(auftragId);
});

/// Provides a single Rapport by its local/server ID.
final rapportFutureProvider =
    FutureProvider.family<RapportLocal?, String>((ref, id) async {
  return RapportRepository.getById(id);
});

/// Provides all Rapporte (across all Auftraege).
final rapporteAllProvider = FutureProvider<List<RapportLocal>>((ref) async {
  return RapportRepository.getAll();
});

/// Provides the total count of Rapporte.
final rapporteCountProvider = FutureProvider<int>((ref) async {
  return RapportRepository.count();
});
