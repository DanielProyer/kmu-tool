import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/kunde_kontakt_local_export.dart';
import 'package:kmu_tool_app/data/models/kunde_kontakt.dart';
import 'package:kmu_tool_app/data/mappers/kunde_kontakt_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class KundeKontaktRepository {
  static Future<List<KundeKontaktLocal>> getByKunde(String kundeId) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('kunden_kontakte')
          .select()
          .eq('kunde_id', kundeId);
      return rows
          .map((r) =>
              KundeKontaktMapper.fromDto(KundeKontakt.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.kundeKontaktLocals
        .filter()
        .kundeIdEqualTo(kundeId)
        .findAll();
  }

  static Stream<List<KundeKontaktLocal>> watchByKunde(String kundeId) {
    if (kIsWeb) return Stream.fromFuture(getByKunde(kundeId));
    final isar = IsarService.instance;
    return isar.kundeKontaktLocals
        .filter()
        .kundeIdEqualTo(kundeId)
        .watch(fireImmediately: true);
  }

  static Future<void> save(KundeKontaktLocal kontakt) async {
    if (kIsWeb) {
      final json = KundeKontaktMapper.toJson(kontakt);
      await SupabaseService.client.from('kunden_kontakte').upsert(json);
      return;
    }
    kontakt.isSynced = false;
    kontakt.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.kundeKontaktLocals.put(kontakt));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      await SupabaseService.client
          .from('kunden_kontakte')
          .delete()
          .eq('id', id);
      return;
    }
    final isar = IsarService.instance;
    await isar.writeTxn(
        () => isar.kundeKontaktLocals.delete(int.parse(id)));
  }
}
