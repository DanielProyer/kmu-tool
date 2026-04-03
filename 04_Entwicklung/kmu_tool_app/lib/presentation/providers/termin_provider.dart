import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/termin.dart';
import '../../data/repositories/termin_repository.dart';

final termineByMonatProvider =
    FutureProvider.family<List<Termin>, DateTime>((ref, monat) async {
  final von = DateTime(monat.year, monat.month, 1);
  final bis = DateTime(monat.year, monat.month + 1, 0); // Letzter Tag des Monats
  return TerminRepository.getAll(von: von, bis: bis);
});

final termineByDatumProvider =
    FutureProvider.family<List<Termin>, DateTime>((ref, datum) async {
  return TerminRepository.getByDatum(datum);
});

final terminProvider =
    FutureProvider.family<Termin?, String>((ref, id) async {
  return TerminRepository.getById(id);
});

final termineHeuteCountProvider = FutureProvider<int>((ref) async {
  return TerminRepository.countHeute();
});
