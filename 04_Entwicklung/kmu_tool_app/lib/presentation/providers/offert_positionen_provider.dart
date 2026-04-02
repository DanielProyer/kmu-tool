/// Offert-Positionen providers using simple FutureProvider pattern.
///
/// For screens that need `.notifier.refresh()`, use the AsyncNotifier-based
/// `offertPositionenProvider` from `providers.dart` instead.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/local/offert_position_local_export.dart';
import 'package:kmu_tool_app/data/repositories/offert_position_repository.dart';

/// Simple FutureProvider for OffertPositionen by Offerte ID.
/// Use `ref.invalidate(offertPositionenFutureProvider(offerteId))` to refresh.
final offertPositionenFutureProvider = FutureProvider.family<
    List<OffertPositionLocal>, String>((ref, offerteId) async {
  return OffertPositionRepository.getByOfferte(offerteId);
});
