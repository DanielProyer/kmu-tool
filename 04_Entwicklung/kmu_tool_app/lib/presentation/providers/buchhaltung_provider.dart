import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/models/konto.dart';
import 'package:kmu_tool_app/data/models/buchung.dart';
import 'package:kmu_tool_app/data/repositories/konto_repository.dart';
import 'package:kmu_tool_app/data/repositories/buchung_repository.dart';

/// Singleton instances (instance-method repos).
final _kontoRepo = KontoRepository();
final _buchungRepo = BuchungRepository();

// ──────────────────────────────────────────────
// Konten
// ──────────────────────────────────────────────

/// Provides the full Kontenplan ordered by Kontonummer.
final kontenProvider = FutureProvider<List<Konto>>((ref) async {
  return _kontoRepo.getAll();
});

/// Provides a single Konto by its ID.
final kontoProvider =
    FutureProvider.family<Konto?, String>((ref, id) async {
  return _kontoRepo.getById(id);
});

/// Provides all Konten of a specific Kontenklasse (1-9).
final kontenByKlasseProvider =
    FutureProvider.family<List<Konto>, int>((ref, klasse) async {
  return _kontoRepo.getByKlasse(klasse);
});

/// Provides all Konten of a specific Typ (aktiv, passiv, aufwand, ertrag).
final kontenByTypProvider =
    FutureProvider.family<List<Konto>, String>((ref, typ) async {
  return _kontoRepo.getByTyp(typ);
});

// ──────────────────────────────────────────────
// Buchungen
// ──────────────────────────────────────────────

/// Provides all Buchungen ordered by datum desc.
final buchungenProvider = FutureProvider<List<Buchung>>((ref) async {
  return _buchungRepo.getAll();
});

/// Provides a single Buchung by its ID.
final buchungProvider =
    FutureProvider.family<Buchung?, String>((ref, id) async {
  return _buchungRepo.getById(id);
});

/// Provides all Buchungen for a given Kontonummer (Soll or Haben).
final buchungenByKontoProvider =
    FutureProvider.family<List<Buchung>, int>((ref, kontonummer) async {
  return _buchungRepo.getByKonto(kontonummer);
});

/// Provides all Buchungen for a specific Rechnung.
final buchungenByRechnungProvider =
    FutureProvider.family<List<Buchung>, String>((ref, rechnungId) async {
  return _buchungRepo.getByRechnung(rechnungId);
});

// ──────────────────────────────────────────────
// Berichte (Bilanz / Erfolgsrechnung Zusammenfassung)
// ──────────────────────────────────────────────

/// Summary data for the Bilanz and Erfolgsrechnung screens.
class BerichteData {
  /// Total of all Aktiv-Konten (Kontenklasse 1).
  final double totalAktiven;

  /// Total of all Passiv-Konten (Kontenklasse 2).
  final double totalPassiven;

  /// Total of all Ertrag-Konten (Kontenklasse 3).
  final double totalErtrag;

  /// Total of all Aufwand-Konten (Kontenklasse 4-6).
  final double totalAufwand;

  /// Ertrag - Aufwand
  double get gewinn => totalErtrag - totalAufwand;

  const BerichteData({
    this.totalAktiven = 0,
    this.totalPassiven = 0,
    this.totalErtrag = 0,
    this.totalAufwand = 0,
  });
}

/// Provides a summary for Bilanz and Erfolgsrechnung based on Konten-Saldi.
final berichteProvider = FutureProvider<BerichteData>((ref) async {
  final konten = await ref.watch(kontenProvider.future);

  double aktiven = 0;
  double passiven = 0;
  double ertrag = 0;
  double aufwand = 0;

  for (final konto in konten) {
    switch (konto.typ) {
      case 'aktiv':
        aktiven += konto.saldo;
      case 'passiv':
        passiven += konto.saldo;
      case 'ertrag':
        ertrag += konto.saldo;
      case 'aufwand':
        aufwand += konto.saldo;
    }
  }

  return BerichteData(
    totalAktiven: aktiven,
    totalPassiven: passiven,
    totalErtrag: ertrag,
    totalAufwand: aufwand,
  );
});
