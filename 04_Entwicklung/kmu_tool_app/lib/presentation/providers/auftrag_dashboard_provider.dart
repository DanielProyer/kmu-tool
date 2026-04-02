import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/models/auftrag_notiz.dart';
import 'package:kmu_tool_app/data/models/auftrag_datei.dart';
import 'package:kmu_tool_app/data/models/auftrag_zugriff.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_notiz_repository.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_datei_repository.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_zugriff_repository.dart';

/// Notizen eines Auftrags.
final auftragNotizenProvider =
    FutureProvider.family<List<AuftragNotiz>, String>((ref, auftragId) {
  return AuftragNotizRepository.getByAuftrag(auftragId);
});

/// Dateien eines Auftrags.
final auftragDateienProvider =
    FutureProvider.family<List<AuftragDatei>, String>((ref, auftragId) {
  return AuftragDateiRepository.getByAuftrag(auftragId);
});

/// Zugriffe eines Auftrags.
final auftragZugriffeProvider =
    FutureProvider.family<List<AuftragZugriff>, String>((ref, auftragId) {
  return AuftragZugriffRepository.getByAuftrag(auftragId);
});
