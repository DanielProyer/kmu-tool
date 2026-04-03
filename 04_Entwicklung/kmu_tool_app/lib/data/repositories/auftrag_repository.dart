import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/data/models/auftrag.dart';
import 'package:kmu_tool_app/data/mappers/auftrag_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';

class AuftragRepository {
  static Future<List<AuftragLocal>> getAll() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('auftraege')
          .select()
          .eq('user_id', userId)
          .eq('is_deleted', false);
      return rows
          .map((r) => AuftragMapper.fromDto(Auftrag.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.auftragLocals.filter().isDeletedEqualTo(false).findAll();
  }

  static Stream<List<AuftragLocal>> watchAll() {
    if (kIsWeb) return Stream.fromFuture(getAll());
    final isar = IsarService.instance;
    return isar.auftragLocals
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  static Future<AuftragLocal?> getById(String id) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('auftraege')
          .select()
          .eq('id', id)
          .limit(1);
      if (rows.isEmpty) return null;
      return AuftragMapper.fromDto(Auftrag.fromJson(rows.first));
    }
    final isar = IsarService.instance;
    return isar.auftragLocals.get(int.parse(id));
  }

  static Future<List<AuftragLocal>> getByKunde(String kundeId) async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('auftraege')
          .select()
          .eq('user_id', userId)
          .eq('kunde_id', kundeId)
          .eq('is_deleted', false);
      return rows
          .map((r) => AuftragMapper.fromDto(Auftrag.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.auftragLocals
        .filter()
        .kundeIdEqualTo(kundeId)
        .isDeletedEqualTo(false)
        .findAll();
  }

  static Future<List<AuftragLocal>> getByStatus(String status) async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('auftraege')
          .select()
          .eq('user_id', userId)
          .eq('status', status)
          .eq('is_deleted', false);
      return rows
          .map((r) => AuftragMapper.fromDto(Auftrag.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.auftragLocals
        .filter()
        .statusEqualTo(status)
        .isDeletedEqualTo(false)
        .findAll();
  }

  static Future<List<AuftragLocal>> getByOfferte(String offerteId) async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('auftraege')
          .select()
          .eq('user_id', userId)
          .eq('offerte_id', offerteId)
          .eq('is_deleted', false);
      return rows
          .map((r) => AuftragMapper.fromDto(Auftrag.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.auftragLocals
        .filter()
        .offerteIdEqualTo(offerteId)
        .isDeletedEqualTo(false)
        .findAll();
  }

  static Future<void> save(AuftragLocal auftrag) async {
    final userId = await BetriebService.getDataOwnerId();
    auftrag.userId = userId;
    if (kIsWeb) {
      final json = AuftragMapper.toJson(auftrag);
      await SupabaseService.client.from('auftraege').upsert(json);
      return;
    }
    auftrag.isSynced = false;
    auftrag.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.auftragLocals.put(auftrag));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      await SupabaseService.client.from('auftraege').delete().eq('id', id);
      return;
    }
    final isar = IsarService.instance;
    final local = await isar.auftragLocals.get(int.parse(id));
    if (local?.serverId != null) {
      await SupabaseService.client
          .from('auftraege')
          .delete()
          .eq('id', local!.serverId!);
    }
    await isar.writeTxn(() => isar.auftragLocals.delete(int.parse(id)));
  }

  static Future<int> count() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('auftraege')
          .select('id')
          .eq('user_id', userId)
          .eq('is_deleted', false);
      return rows.length;
    }
    final isar = IsarService.instance;
    return isar.auftragLocals.filter().isDeletedEqualTo(false).count();
  }
}
