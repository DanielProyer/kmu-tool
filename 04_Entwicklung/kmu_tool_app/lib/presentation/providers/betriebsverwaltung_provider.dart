import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bankverbindung.dart';
import '../../data/models/sozialversicherung.dart';
import '../../data/models/mitarbeiter_berechtigung.dart';
import '../../data/models/lohnabrechnung.dart';
import '../../data/repositories/bankverbindung_repository.dart';
import '../../data/repositories/sozialversicherung_repository.dart';
import '../../data/repositories/mitarbeiter_berechtigung_repository.dart';
import '../../data/repositories/lohnabrechnung_repository.dart';

// --- Bankverbindungen ---
final bankverbindungenListProvider =
    FutureProvider<List<Bankverbindung>>((ref) async {
  return BankverbindungRepository.getAll();
});

final bankverbindungProvider =
    FutureProvider.family<Bankverbindung?, String>((ref, id) async {
  return BankverbindungRepository.getById(id);
});

// --- Sozialversicherung ---
final sozialversicherungProvider =
    FutureProvider<Sozialversicherung>((ref) async {
  return SozialversicherungRepository.get();
});

// --- Mitarbeiter-Berechtigungen ---
final mitarbeiterBerechtigungenProvider = FutureProvider.family<
    List<MitarbeiterBerechtigung>, String>((ref, mitarbeiterId) async {
  return MitarbeiterBerechtigungRepository.getForMitarbeiter(mitarbeiterId);
});

// --- Lohnabrechnungen ---
final lohnabrechnungenJahrProvider =
    FutureProvider.family<List<Lohnabrechnung>, int>((ref, jahr) async {
  return LohnabrechnungRepository.getAll(jahr: jahr);
});

final lohnabrechnungMonatProvider = FutureProvider.family<
    List<Lohnabrechnung>, ({int jahr, int monat})>((ref, params) async {
  return LohnabrechnungRepository.getForMonat(params.jahr, params.monat);
});

final lohnabrechnungDetailProvider =
    FutureProvider.family<Lohnabrechnung?, String>((ref, id) async {
  return LohnabrechnungRepository.getById(id);
});
