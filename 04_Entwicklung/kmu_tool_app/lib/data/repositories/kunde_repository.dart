import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/models/kunde.dart';
import 'package:kmu_tool_app/data/mappers/kunde_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';

class KundeRepository {
  static Future<List<KundeLocal>> getAll() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('kunden')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);
      return rows
          .map((r) => KundeMapper.fromDto(Kunde.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.kundeLocals.filter().isDeletedEqualTo(false).findAll();
  }

  static Stream<List<KundeLocal>> watchAll() {
    if (kIsWeb) return Stream.fromFuture(getAll());
    final isar = IsarService.instance;
    return isar.kundeLocals
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  static Future<KundeLocal?> getById(String id) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('kunden')
          .select()
          .eq('id', id)
          .limit(1);
      if (rows.isEmpty) return null;
      return KundeMapper.fromDto(Kunde.fromJson(rows.first));
    }
    final isar = IsarService.instance;
    return isar.kundeLocals.get(int.parse(id));
  }

  static Future<void> save(KundeLocal kunde) async {
    final userId = await BetriebService.getDataOwnerId();
    kunde.userId = userId;
    if (kIsWeb) {
      final json = KundeMapper.toJson(kunde);
      await SupabaseService.client.from('kunden').upsert(json);
      return;
    }
    kunde.isSynced = false;
    kunde.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.kundeLocals.put(kunde));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      await SupabaseService.client.from('kunden').delete().eq('id', id);
      return;
    }
    final isar = IsarService.instance;
    final local = await isar.kundeLocals.get(int.parse(id));
    if (local?.serverId != null) {
      await SupabaseService.client
          .from('kunden')
          .delete()
          .eq('id', local!.serverId!);
    }
    await isar.writeTxn(() => isar.kundeLocals.delete(int.parse(id)));
  }

  static Future<int> count() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('kunden')
          .select('id')
          .eq('user_id', userId)
          .eq('is_deleted', false);
      return rows.length;
    }
    final isar = IsarService.instance;
    return isar.kundeLocals.filter().isDeletedEqualTo(false).count();
  }
}
