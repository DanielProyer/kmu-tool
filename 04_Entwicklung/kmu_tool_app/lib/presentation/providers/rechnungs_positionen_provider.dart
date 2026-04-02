import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/models/rechnungs_position.dart';
import 'package:kmu_tool_app/data/repositories/rechnungs_position_repository.dart';

/// Singleton instance (instance-method repo).
final _repo = RechnungsPositionRepository();

/// Provides all RechnungsPositionen for a given Rechnung, ordered by position_nr.
final rechnungsPositionenProvider = FutureProvider.family<
    List<RechnungsPosition>, String>((ref, rechnungId) async {
  return _repo.getByRechnung(rechnungId);
});
