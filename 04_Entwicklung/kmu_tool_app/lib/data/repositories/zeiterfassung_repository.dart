import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/zeiterfassung_local_export.dart';
import 'package:kmu_tool_app/data/models/zeiterfassung.dart';
import 'package:kmu_tool_app/data/mappers/zeiterfassung_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';

class ZeiterfassungRepository {
  static Future<List<ZeiterfassungLocal>> getAll() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('zeiterfassungen')
          .select()
          .eq('user_id', userId);
      return rows
          .map((r) =>
              ZeiterfassungMapper.fromDto(Zeiterfassung.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.zeiterfassungLocals.where().findAll();
  }

  static Stream<List<ZeiterfassungLocal>> watchAll() {
    if (kIsWeb) return Stream.fromFuture(getAll());
    final isar = IsarService.instance;
    return isar.zeiterfassungLocals.where().watch(fireImmediately: true);
  }

  static Future<ZeiterfassungLocal?> getById(String id) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('zeiterfassungen')
          .select()
          .eq('id', id)
          .limit(1);
      if (rows.isEmpty) return null;
      return ZeiterfassungMapper.fromDto(
          Zeiterfassung.fromJson(rows.first));
    }
    final isar = IsarService.instance;
    return isar.zeiterfassungLocals.get(int.parse(id));
  }

  static Future<List<ZeiterfassungLocal>> getByAuftrag(
      String auftragId) async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('zeiterfassungen')
          .select()
          .eq('user_id', userId)
          .eq('auftrag_id', auftragId);
      return rows
          .map((r) =>
              ZeiterfassungMapper.fromDto(Zeiterfassung.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.zeiterfassungLocals
        .filter()
        .auftragIdEqualTo(auftragId)
        .findAll();
  }

  static Future<void> save(ZeiterfassungLocal zeiterfassung) async {
    final userId = await BetriebService.getDataOwnerId();
    zeiterfassung.userId = userId;
    if (kIsWeb) {
      final json = ZeiterfassungMapper.toJson(zeiterfassung);
      await SupabaseService.client.from('zeiterfassungen').upsert(json);
      return;
    }
    zeiterfassung.isSynced = false;
    zeiterfassung.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(
        () => isar.zeiterfassungLocals.put(zeiterfassung));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      await SupabaseService.client
          .from('zeiterfassungen')
          .delete()
          .eq('id', id);
      return;
    }
    final isar = IsarService.instance;
    await isar.writeTxn(
        () => isar.zeiterfassungLocals.delete(int.parse(id)));
  }

  static Future<int> count() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('zeiterfassungen')
          .select('id')
          .eq('user_id', userId);
      return rows.length;
    }
    final isar = IsarService.instance;
    return isar.zeiterfassungLocals.where().count();
  }
}
