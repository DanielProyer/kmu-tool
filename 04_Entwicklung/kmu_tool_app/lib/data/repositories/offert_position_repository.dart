import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/offert_position_local_export.dart';
import 'package:kmu_tool_app/data/models/offert_position.dart';
import 'package:kmu_tool_app/data/mappers/offert_position_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class OffertPositionRepository {
  static Future<List<OffertPositionLocal>> getByOfferte(
      String offerteId) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('offert_positionen')
          .select()
          .eq('offerte_id', offerteId)
          .order('position_nr');
      return rows
          .map((r) =>
              OffertPositionMapper.fromDto(OffertPosition.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.offertPositionLocals
        .filter()
        .offerteIdEqualTo(offerteId)
        .sortByPositionNr()
        .findAll();
  }

  static Stream<List<OffertPositionLocal>> watchByOfferte(
      String offerteId) {
    if (kIsWeb) return Stream.fromFuture(getByOfferte(offerteId));
    final isar = IsarService.instance;
    return isar.offertPositionLocals
        .filter()
        .offerteIdEqualTo(offerteId)
        .sortByPositionNr()
        .watch(fireImmediately: true);
  }

  static Future<void> save(OffertPositionLocal position) async {
    if (kIsWeb) {
      final json = OffertPositionMapper.toJson(position);
      await SupabaseService.client.from('offert_positionen').upsert(json);
      return;
    }
    position.isSynced = false;
    position.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.offertPositionLocals.put(position));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      await SupabaseService.client
          .from('offert_positionen')
          .delete()
          .eq('id', id);
      return;
    }
    final isar = IsarService.instance;
    await isar.writeTxn(
        () => isar.offertPositionLocals.delete(int.parse(id)));
  }
}
