import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import 'package:kmu_tool_app/services/storage/isar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/services/connectivity/connectivity_service.dart';

// Local Models
import 'package:kmu_tool_app/data/local/sync_meta_local.dart';
import 'package:kmu_tool_app/data/local/kunde_local.dart';
import 'package:kmu_tool_app/data/local/kunde_kontakt_local.dart';
import 'package:kmu_tool_app/data/local/offerte_local.dart';
import 'package:kmu_tool_app/data/local/offert_position_local.dart';
import 'package:kmu_tool_app/data/local/auftrag_local.dart';
import 'package:kmu_tool_app/data/local/zeiterfassung_local.dart';
import 'package:kmu_tool_app/data/local/rapport_local.dart';

// DTOs
import 'package:kmu_tool_app/data/models/kunde.dart';
import 'package:kmu_tool_app/data/models/kunde_kontakt.dart';
import 'package:kmu_tool_app/data/models/offerte.dart';
import 'package:kmu_tool_app/data/models/offert_position.dart';
import 'package:kmu_tool_app/data/models/auftrag.dart';
import 'package:kmu_tool_app/data/models/zeiterfassung.dart';
import 'package:kmu_tool_app/data/models/rapport.dart';

// Mappers
import 'package:kmu_tool_app/data/mappers/kunde_mapper.dart';
import 'package:kmu_tool_app/data/mappers/kunde_kontakt_mapper.dart';
import 'package:kmu_tool_app/data/mappers/offerte_mapper.dart';
import 'package:kmu_tool_app/data/mappers/offert_position_mapper.dart';
import 'package:kmu_tool_app/data/mappers/auftrag_mapper.dart';
import 'package:kmu_tool_app/data/mappers/zeiterfassung_mapper.dart';
import 'package:kmu_tool_app/data/mappers/rapport_mapper.dart';

enum SyncState { idle, syncing, error }

class SyncResult {
  final int pushed;
  final int pulled;
  final List<String> errors;

  SyncResult({this.pushed = 0, this.pulled = 0, List<String>? errors})
      : errors = errors ?? [];

  bool get hasErrors => errors.isNotEmpty;
}

class SyncService {
  static Isar get _isar => IsarService.instance;
  static SupabaseClient get _client => SupabaseService.client;

  // === State ===
  static final _stateController = StreamController<SyncState>.broadcast();
  static Stream<SyncState> get stateStream => _stateController.stream;
  static SyncState _state = SyncState.idle;
  static SyncState get state => _state;
  static bool _isSyncing = false;

  static void _setState(SyncState s) {
    _state = s;
    _stateController.add(s);
  }

  // === Connectivity Listener ===
  static StreamSubscription<bool>? _subscription;

  static void startListening() {
    _subscription?.cancel();
    _subscription = ConnectivityService.onConnectivityChanged.listen((online) {
      if (online) syncAll();
    });
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  // === Sync Orchestrator ===
  static Future<SyncResult> syncAll() async {
    if (_isSyncing || !ConnectivityService.isOnline) return SyncResult();

    _isSyncing = true;
    _setState(SyncState.syncing);

    int totalPushed = 0;
    int totalPulled = 0;
    final errors = <String>[];

    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) return SyncResult(errors: ['Nicht eingeloggt']);

      // Sync in Tier-Reihenfolge (FK-Abhängigkeiten)
      final tiers = <List<Future<({int pushed, int pulled})> Function()>>[
        // Tier 1: Kunden (unabhängig)
        [() => _syncKunden(userId)],
        // Tier 2: Kunden-Kontakte, Offerten, Aufträge (→ Kunden)
        [
          () => _syncKundenKontakte(userId),
          () => _syncOfferten(userId),
          () => _syncAuftraege(userId),
        ],
        // Tier 3: Offert-Positionen, Zeiterfassung, Rapporte (→ Offerte/Auftrag)
        [
          () => _syncOffertPositionen(userId),
          () => _syncZeiterfassungen(userId),
          () => _syncRapporte(userId),
        ],
      ];

      for (final tier in tiers) {
        final results = await Future.wait(
          tier.map((fn) async {
            try {
              return await fn();
            } catch (e) {
              errors.add(e.toString());
              debugPrint('Sync error: $e');
              return (pushed: 0, pulled: 0);
            }
          }),
        );
        for (final r in results) {
          totalPushed += r.pushed;
          totalPulled += r.pulled;
        }
      }

      _setState(errors.isEmpty ? SyncState.idle : SyncState.error);
    } catch (e) {
      errors.add(e.toString());
      _setState(SyncState.error);
    } finally {
      _isSyncing = false;
    }

    debugPrint('Sync: $totalPushed pushed, $totalPulled pulled, ${errors.length} errors');
    return SyncResult(pushed: totalPushed, pulled: totalPulled, errors: errors);
  }

  // === SyncMeta Helpers ===
  static Future<SyncMetaLocal> _getMeta(String entity) async {
    return await _isar.syncMetaLocals
            .filter()
            .entityNameEqualTo(entity)
            .findFirst() ??
        (SyncMetaLocal()..entityName = entity);
  }

  static Future<void> _updateMeta(String entity) async {
    final meta = await _getMeta(entity);
    meta.lastPullAt = DateTime.now().toUtc();
    await _isar.writeTxn(() => _isar.syncMetaLocals.put(meta));
  }

  // === Generic Push Helper ===
  static Future<List<T>> _pushToSupabase<T>(
    String table,
    List<T> unsynced,
    Map<String, dynamic> Function(T) toJson,
    void Function(T, String) onSuccess,
  ) async {
    final pushed = <T>[];
    for (final local in unsynced) {
      try {
        final json = toJson(local);
        final res =
            await _client.from(table).upsert(json).select('id').single();
        onSuccess(local, res['id'] as String);
        pushed.add(local);
      } catch (e) {
        debugPrint('Push $table error: $e');
      }
    }
    return pushed;
  }

  // === Generic Pull Helper ===
  static Future<List<Map<String, dynamic>>> _pullRows(
    String table,
    String entity,
    String userId,
  ) async {
    final meta = await _getMeta(entity);
    var query = _client.from(table).select().eq('user_id', userId);
    if (meta.lastPullAt != null) {
      query = query.gt('updated_at', meta.lastPullAt!.toUtc().toIso8601String());
    }
    return await query;
  }

  // Pull helper for child tables (no user_id column)
  static Future<List<Map<String, dynamic>>> _pullChildRows(
    String table,
    String entity,
    String parentColumn,
    List<String> parentIds,
  ) async {
    if (parentIds.isEmpty) return [];
    final meta = await _getMeta(entity);
    var query = _client.from(table).select().inFilter(parentColumn, parentIds);
    if (meta.lastPullAt != null) {
      query = query.gt('updated_at', meta.lastPullAt!.toUtc().toIso8601String());
    }
    return await query;
  }

  // ============================================================
  // TIER 1: Kunden
  // ============================================================

  static Future<({int pushed, int pulled})> _syncKunden(String uid) async {
    final unsynced =
        await _isar.kundeLocals.filter().isSyncedEqualTo(false).findAll();
    final pushed = await _pushToSupabase<KundeLocal>(
      'kunden', unsynced, KundeMapper.toJson,
      (l, id) { l.serverId ??= id; l.isSynced = true; },
    );
    if (pushed.isNotEmpty) {
      await _isar.writeTxn(() => _isar.kundeLocals.putAll(pushed));
    }

    final rows = await _pullRows('kunden', 'kunden', uid);
    final toSave = <KundeLocal>[];
    for (final row in rows) {
      final dto = Kunde.fromJson(row);
      final ex = await _isar.kundeLocals.filter().serverIdEqualTo(dto.id).findFirst();
      if (ex != null && !ex.isSynced &&
          (ex.lastModifiedAt?.isAfter(dto.updatedAt ?? DateTime(2000)) ?? false)) {
        continue;
      }
      toSave.add(KundeMapper.fromDto(dto, existing: ex));
    }
    if (toSave.isNotEmpty) {
      await _isar.writeTxn(() => _isar.kundeLocals.putAll(toSave));
    }
    await _updateMeta('kunden');
    return (pushed: pushed.length, pulled: toSave.length);
  }

  // ============================================================
  // TIER 2: Kunden-Kontakte, Offerten, Aufträge
  // ============================================================

  static Future<({int pushed, int pulled})> _syncKundenKontakte(String uid) async {
    final unsynced =
        await _isar.kundeKontaktLocals.filter().isSyncedEqualTo(false).findAll();
    final pushed = await _pushToSupabase<KundeKontaktLocal>(
      'kunden_kontakte', unsynced, KundeKontaktMapper.toJson,
      (l, id) { l.serverId ??= id; l.isSynced = true; },
    );
    if (pushed.isNotEmpty) {
      await _isar.writeTxn(() => _isar.kundeKontaktLocals.putAll(pushed));
    }

    // Get parent IDs for child pull
    final kundenIds = await _isar.kundeLocals.where().findAll();
    final serverIds = kundenIds.where((k) => k.serverId != null).map((k) => k.serverId!).toList();
    final rows = await _pullChildRows('kunden_kontakte', 'kunden_kontakte', 'kunde_id', serverIds);
    final toSave = <KundeKontaktLocal>[];
    for (final row in rows) {
      final dto = KundeKontakt.fromJson(row);
      final ex = await _isar.kundeKontaktLocals.filter().serverIdEqualTo(dto.id).findFirst();
      if (ex != null && !ex.isSynced &&
          (ex.lastModifiedAt?.isAfter(dto.updatedAt ?? DateTime(2000)) ?? false)) {
        continue;
      }
      toSave.add(KundeKontaktMapper.fromDto(dto, existing: ex));
    }
    if (toSave.isNotEmpty) {
      await _isar.writeTxn(() => _isar.kundeKontaktLocals.putAll(toSave));
    }
    await _updateMeta('kunden_kontakte');
    return (pushed: pushed.length, pulled: toSave.length);
  }

  static Future<({int pushed, int pulled})> _syncOfferten(String uid) async {
    final unsynced =
        await _isar.offerteLocals.filter().isSyncedEqualTo(false).findAll();
    final pushed = await _pushToSupabase<OfferteLocal>(
      'offerten', unsynced, OfferteMapper.toJson,
      (l, id) { l.serverId ??= id; l.isSynced = true; },
    );
    if (pushed.isNotEmpty) {
      await _isar.writeTxn(() => _isar.offerteLocals.putAll(pushed));
    }

    final rows = await _pullRows('offerten', 'offerten', uid);
    final toSave = <OfferteLocal>[];
    for (final row in rows) {
      final dto = Offerte.fromJson(row);
      final ex = await _isar.offerteLocals.filter().serverIdEqualTo(dto.id).findFirst();
      if (ex != null && !ex.isSynced &&
          (ex.lastModifiedAt?.isAfter(dto.updatedAt ?? DateTime(2000)) ?? false)) {
        continue;
      }
      toSave.add(OfferteMapper.fromDto(dto, existing: ex));
    }
    if (toSave.isNotEmpty) {
      await _isar.writeTxn(() => _isar.offerteLocals.putAll(toSave));
    }
    await _updateMeta('offerten');
    return (pushed: pushed.length, pulled: toSave.length);
  }

  static Future<({int pushed, int pulled})> _syncAuftraege(String uid) async {
    final unsynced =
        await _isar.auftragLocals.filter().isSyncedEqualTo(false).findAll();
    final pushed = await _pushToSupabase<AuftragLocal>(
      'auftraege', unsynced, AuftragMapper.toJson,
      (l, id) { l.serverId ??= id; l.isSynced = true; },
    );
    if (pushed.isNotEmpty) {
      await _isar.writeTxn(() => _isar.auftragLocals.putAll(pushed));
    }

    final rows = await _pullRows('auftraege', 'auftraege', uid);
    final toSave = <AuftragLocal>[];
    for (final row in rows) {
      final dto = Auftrag.fromJson(row);
      final ex = await _isar.auftragLocals.filter().serverIdEqualTo(dto.id).findFirst();
      if (ex != null && !ex.isSynced &&
          (ex.lastModifiedAt?.isAfter(dto.updatedAt ?? DateTime(2000)) ?? false)) {
        continue;
      }
      toSave.add(AuftragMapper.fromDto(dto, existing: ex));
    }
    if (toSave.isNotEmpty) {
      await _isar.writeTxn(() => _isar.auftragLocals.putAll(toSave));
    }
    await _updateMeta('auftraege');
    return (pushed: pushed.length, pulled: toSave.length);
  }

  // ============================================================
  // TIER 3: Offert-Positionen, Zeiterfassung, Rapporte
  // ============================================================

  static Future<({int pushed, int pulled})> _syncOffertPositionen(String uid) async {
    final unsynced =
        await _isar.offertPositionLocals.filter().isSyncedEqualTo(false).findAll();
    final pushed = await _pushToSupabase<OffertPositionLocal>(
      'offert_positionen', unsynced, OffertPositionMapper.toJson,
      (l, id) { l.serverId ??= id; l.isSynced = true; },
    );
    if (pushed.isNotEmpty) {
      await _isar.writeTxn(() => _isar.offertPositionLocals.putAll(pushed));
    }

    final offertenIds = await _isar.offerteLocals.where().findAll();
    final serverIds = offertenIds.where((o) => o.serverId != null).map((o) => o.serverId!).toList();
    final rows = await _pullChildRows('offert_positionen', 'offert_positionen', 'offerte_id', serverIds);
    final toSave = <OffertPositionLocal>[];
    for (final row in rows) {
      final dto = OffertPosition.fromJson(row);
      final ex = await _isar.offertPositionLocals.filter().serverIdEqualTo(dto.id).findFirst();
      if (ex != null && !ex.isSynced &&
          (ex.lastModifiedAt?.isAfter(dto.updatedAt ?? DateTime(2000)) ?? false)) {
        continue;
      }
      toSave.add(OffertPositionMapper.fromDto(dto, existing: ex));
    }
    if (toSave.isNotEmpty) {
      await _isar.writeTxn(() => _isar.offertPositionLocals.putAll(toSave));
    }
    await _updateMeta('offert_positionen');
    return (pushed: pushed.length, pulled: toSave.length);
  }

  static Future<({int pushed, int pulled})> _syncZeiterfassungen(String uid) async {
    final unsynced =
        await _isar.zeiterfassungLocals.filter().isSyncedEqualTo(false).findAll();
    final pushed = await _pushToSupabase<ZeiterfassungLocal>(
      'zeiterfassungen', unsynced, ZeiterfassungMapper.toJson,
      (l, id) { l.serverId ??= id; l.isSynced = true; },
    );
    if (pushed.isNotEmpty) {
      await _isar.writeTxn(() => _isar.zeiterfassungLocals.putAll(pushed));
    }

    final rows = await _pullRows('zeiterfassungen', 'zeiterfassungen', uid);
    final toSave = <ZeiterfassungLocal>[];
    for (final row in rows) {
      final dto = Zeiterfassung.fromJson(row);
      final ex = await _isar.zeiterfassungLocals.filter().serverIdEqualTo(dto.id).findFirst();
      if (ex != null && !ex.isSynced &&
          (ex.lastModifiedAt?.isAfter(dto.updatedAt ?? DateTime(2000)) ?? false)) {
        continue;
      }
      toSave.add(ZeiterfassungMapper.fromDto(dto, existing: ex));
    }
    if (toSave.isNotEmpty) {
      await _isar.writeTxn(() => _isar.zeiterfassungLocals.putAll(toSave));
    }
    await _updateMeta('zeiterfassungen');
    return (pushed: pushed.length, pulled: toSave.length);
  }

  static Future<({int pushed, int pulled})> _syncRapporte(String uid) async {
    final unsynced =
        await _isar.rapportLocals.filter().isSyncedEqualTo(false).findAll();
    final pushed = await _pushToSupabase<RapportLocal>(
      'rapporte', unsynced, RapportMapper.toJson,
      (l, id) { l.serverId ??= id; l.isSynced = true; },
    );
    if (pushed.isNotEmpty) {
      await _isar.writeTxn(() => _isar.rapportLocals.putAll(pushed));
    }

    final rows = await _pullRows('rapporte', 'rapporte', uid);
    final toSave = <RapportLocal>[];
    for (final row in rows) {
      final dto = Rapport.fromJson(row);
      final ex = await _isar.rapportLocals.filter().serverIdEqualTo(dto.id).findFirst();
      if (ex != null && !ex.isSynced &&
          (ex.lastModifiedAt?.isAfter(dto.updatedAt ?? DateTime(2000)) ?? false)) {
        continue;
      }
      toSave.add(RapportMapper.fromDto(dto, existing: ex));
    }
    if (toSave.isNotEmpty) {
      await _isar.writeTxn(() => _isar.rapportLocals.putAll(toSave));
    }
    await _updateMeta('rapporte');
    return (pushed: pushed.length, pulled: toSave.length);
  }
}
