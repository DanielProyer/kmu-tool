import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/models/offerte.dart';
import 'package:kmu_tool_app/data/mappers/offerte_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class OfferteRepository {
  static String get _userId => SupabaseService.currentUser!.id;

  static Future<List<OfferteLocal>> getAll() async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('offerten')
          .select()
          .eq('user_id', _userId)
          .eq('is_deleted', false);
      return rows
          .map((r) => OfferteMapper.fromDto(Offerte.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.offerteLocals.filter().isDeletedEqualTo(false).findAll();
  }

  static Stream<List<OfferteLocal>> watchAll() {
    if (kIsWeb) return Stream.fromFuture(getAll());
    final isar = IsarService.instance;
    return isar.offerteLocals
        .filter()
        .isDeletedEqualTo(false)
        .watch(fireImmediately: true);
  }

  static Future<OfferteLocal?> getById(String id) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('offerten')
          .select()
          .eq('id', id)
          .limit(1);
      if (rows.isEmpty) return null;
      return OfferteMapper.fromDto(Offerte.fromJson(rows.first));
    }
    final isar = IsarService.instance;
    return isar.offerteLocals.get(int.parse(id));
  }

  static Future<List<OfferteLocal>> getByKunde(String kundeId) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('offerten')
          .select()
          .eq('user_id', _userId)
          .eq('kunde_id', kundeId)
          .eq('is_deleted', false);
      return rows
          .map((r) => OfferteMapper.fromDto(Offerte.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.offerteLocals
        .filter()
        .kundeIdEqualTo(kundeId)
        .isDeletedEqualTo(false)
        .findAll();
  }

  static Future<List<OfferteLocal>> getByStatus(String status) async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('offerten')
          .select()
          .eq('user_id', _userId)
          .eq('status', status)
          .eq('is_deleted', false);
      return rows
          .map((r) => OfferteMapper.fromDto(Offerte.fromJson(r)))
          .toList();
    }
    final isar = IsarService.instance;
    return isar.offerteLocals
        .filter()
        .statusEqualTo(status)
        .isDeletedEqualTo(false)
        .findAll();
  }

  static Future<void> save(OfferteLocal offerte) async {
    offerte.userId = _userId;
    if (kIsWeb) {
      final json = OfferteMapper.toJson(offerte);
      await SupabaseService.client.from('offerten').upsert(json);
      return;
    }
    offerte.isSynced = false;
    offerte.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.offerteLocals.put(offerte));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      await SupabaseService.client.from('offerten').delete().eq('id', id);
      return;
    }
    final isar = IsarService.instance;
    final local = await isar.offerteLocals.get(int.parse(id));
    if (local?.serverId != null) {
      await SupabaseService.client
          .from('offerten')
          .delete()
          .eq('id', local!.serverId!);
    }
    await isar.writeTxn(() => isar.offerteLocals.delete(int.parse(id)));
  }

  static Future<int> count() async {
    if (kIsWeb) {
      final rows = await SupabaseService.client
          .from('offerten')
          .select('id')
          .eq('user_id', _userId)
          .eq('is_deleted', false);
      return rows.length;
    }
    final isar = IsarService.instance;
    return isar.offerteLocals.filter().isDeletedEqualTo(false).count();
  }
}
