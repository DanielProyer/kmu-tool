import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/rapport_local_export.dart';
import 'package:kmu_tool_app/data/models/rapport.dart';
import 'package:kmu_tool_app/data/mappers/rapport_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import '../../services/auth/betrieb_service.dart';

class RapportRepository {
  static Future<List<RapportLocal>> getAll() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('rapporte')
          .select()
          .eq('user_id', userId);
      return rows
          .map((r) => RapportMapper.fromDto(Rapport.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.rapportLocals.where().findAll();
  }

  static Stream<List<RapportLocal>> watchAll() {
    if (kIsWeb) return Stream.fromFuture(getAll());
    final isar = IsarService.instance;
    return isar.rapportLocals.where().watch(fireImmediately: true);
  }

  static Future<RapportLocal?> getById(String id) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('rapporte')
          .select()
          .eq('id', id)
          .limit(1);
      if (rows.isEmpty) return null;
      return RapportMapper.fromDto(Rapport.fromJson(rows.first));
    }
    final isar = IsarService.instance;
    return isar.rapportLocals.get(int.parse(id));
  }

  static Future<List<RapportLocal>> getByAuftrag(
      String auftragId) async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('rapporte')
          .select()
          .eq('user_id', userId)
          .eq('auftrag_id', auftragId);
      return rows
          .map((r) => RapportMapper.fromDto(Rapport.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.rapportLocals
        .filter()
        .auftragIdEqualTo(auftragId)
        .findAll();
  }

  static Future<void> save(RapportLocal rapport) async {
    final userId = await BetriebService.getDataOwnerId();
    rapport.userId = userId;
    if (kIsWeb) {
      final json = RapportMapper.toJson(rapport);
      await SupabaseService.client.from('rapporte').upsert(json);
      return;
    }
    rapport.isSynced = false;
    rapport.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.rapportLocals.put(rapport));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      await SupabaseService.client.from('rapporte').delete().eq('id', id);
      return;
    }
    final isar = IsarService.instance;
    final local = await isar.rapportLocals.get(int.parse(id));
    if (local?.serverId != null) {
      await SupabaseService.client
          .from('rapporte')
          .delete()
          .eq('id', local!.serverId!);
    }
    await isar.writeTxn(() => isar.rapportLocals.delete(int.parse(id)));
  }

  static Future<int> count() async {
    if (kIsWeb) {
      final userId = await BetriebService.getDataOwnerId();
      final rows = await SupabaseService.client
          .from('rapporte')
          .select('id')
          .eq('user_id', userId);
      return rows.length;
    }
    final isar = IsarService.instance;
    return isar.rapportLocals.where().count();
  }
}
