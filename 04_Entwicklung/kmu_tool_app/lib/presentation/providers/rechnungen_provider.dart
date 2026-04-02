import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/models/rechnung.dart';
import 'package:kmu_tool_app/data/repositories/rechnung_repository.dart';

/// Singleton instance of RechnungRepository.
/// The rechnung repos use instance methods (not static), so we share one.
final _repo = RechnungRepository();

/// Provides the full list of Rechnungen (ordered by datum desc).
final rechnungenListProvider = FutureProvider<List<Rechnung>>((ref) async {
  return _repo.getAll();
});

/// Provides a single Rechnung by its ID.
final rechnungProvider =
    FutureProvider.family<Rechnung?, String>((ref, id) async {
  return _repo.getById(id);
});

/// Provides all Rechnungen for a given Kunde.
final rechnungenByKundeProvider =
    FutureProvider.family<List<Rechnung>, String>((ref, kundeId) async {
  return _repo.getByKunde(kundeId);
});

/// Provides all Rechnungen for a given Auftrag.
final rechnungenByAuftragProvider =
    FutureProvider.family<List<Rechnung>, String>((ref, auftragId) async {
  return _repo.getByAuftrag(auftragId);
});

/// Provides Rechnungen filtered by status (e.g. 'entwurf', 'gesendet', 'bezahlt').
final rechnungenByStatusProvider =
    FutureProvider.family<List<Rechnung>, String>((ref, status) async {
  return _repo.getByStatus(status);
});

/// Provides all open Rechnungen (entwurf, gesendet, gemahnt).
final offeneRechnungenProvider = FutureProvider<List<Rechnung>>((ref) async {
  return _repo.getOffene();
});

/// Provides the total CHF amount of all open Rechnungen.
final offeneRechnungenSummeProvider = FutureProvider<double>((ref) async {
  return _repo.summeOffene();
});
