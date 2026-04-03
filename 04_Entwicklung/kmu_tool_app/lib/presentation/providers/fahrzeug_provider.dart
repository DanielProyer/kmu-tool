import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/fahrzeug.dart';
import '../../data/repositories/fahrzeug_repository.dart';

final fahrzeugeListProvider = FutureProvider<List<Fahrzeug>>((ref) async {
  return FahrzeugRepository.getAll();
});

final fahrzeugProvider =
    FutureProvider.family<Fahrzeug?, String>((ref, id) async {
  return FahrzeugRepository.getById(id);
});
