import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/mitarbeiter.dart';
import '../../data/repositories/mitarbeiter_repository.dart';

final mitarbeiterListProvider = FutureProvider<List<Mitarbeiter>>((ref) async {
  return MitarbeiterRepository.getAll();
});

final mitarbeiterProvider =
    FutureProvider.family<Mitarbeiter?, String>((ref, id) async {
  return MitarbeiterRepository.getById(id);
});
