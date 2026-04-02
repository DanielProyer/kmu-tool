import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kmu_tool_app/data/local/artikel_local_export.dart';
import 'package:kmu_tool_app/data/models/artikel.dart';
import 'package:kmu_tool_app/data/mappers/artikel_mapper.dart';
import 'package:kmu_tool_app/services/storage/isar_service_export.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class ArtikelRepository {
  static Future<List<ArtikelLocal>> getAll() async {
    if (kIsWeb) {
      try {
        final rows = await SupabaseService.client
            .from('artikel')
            .select()
            .eq('is_deleted', false)
            .order('bezeichnung');
        return rows
            .map((r) => ArtikelMapper.fromDto(Artikel.fromJson(r)))
            .toList();
      } catch (_) {
        return []; // Tabelle existiert noch nicht (Migration 013)
      }
    }
    final isar = IsarService.instance;
    return isar.artikelLocals
        .filter()
        .isDeletedEqualTo(false)
        .sortByBezeichnung()
        .findAll();
  }

  static Future<ArtikelLocal?> getById(String id) async {
    if (kIsWeb) {
      try {
        final rows = await SupabaseService.client
            .from('artikel')
            .select()
            .eq('id', id)
            .limit(1);
        if (rows.isEmpty) return null;
        return ArtikelMapper.fromDto(Artikel.fromJson(rows.first));
      } catch (_) {
        return null;
      }
    }
    final isar = IsarService.instance;
    return isar.artikelLocals.get(int.parse(id));
  }

  static Future<List<ArtikelLocal>> getByKategorie(String kategorie) async {
    if (kIsWeb) {
      try {
        final rows = await SupabaseService.client
            .from('artikel')
            .select()
            .eq('is_deleted', false)
            .eq('kategorie', kategorie)
            .order('bezeichnung');
        return rows
            .map((r) => ArtikelMapper.fromDto(Artikel.fromJson(r)))
            .toList();
      } catch (_) {
        return [];
      }
    }
    final isar = IsarService.instance;
    return isar.artikelLocals
        .filter()
        .isDeletedEqualTo(false)
        .kategorieEqualTo(kategorie)
        .sortByBezeichnung()
        .findAll();
  }

  static Future<List<ArtikelLocal>> search(String query) async {
    if (kIsWeb) {
      try {
        final rows = await SupabaseService.client
            .from('artikel')
            .select()
            .eq('is_deleted', false)
            .or('bezeichnung.ilike.%$query%,artikel_nr.ilike.%$query%')
            .order('bezeichnung')
            .limit(20);
        return rows
            .map((r) => ArtikelMapper.fromDto(Artikel.fromJson(r)))
            .toList();
      } catch (_) {
        return [];
      }
    }
    final isar = IsarService.instance;
    final lowerQuery = query.toLowerCase();
    final all = await isar.artikelLocals
        .filter()
        .isDeletedEqualTo(false)
        .sortByBezeichnung()
        .findAll();
    return all.where((a) {
      return a.bezeichnung.toLowerCase().contains(lowerQuery) ||
          (a.artikelNr?.toLowerCase().contains(lowerQuery) ?? false);
    }).take(20).toList();
  }

  static Future<void> save(ArtikelLocal artikel) async {
    if (kIsWeb) {
      try {
        final json = ArtikelMapper.toJson(artikel);
        await SupabaseService.client.from('artikel').upsert(json);
      } catch (_) {
        // Tabelle existiert noch nicht
      }
      return;
    }
    artikel.isSynced = false;
    artikel.lastModifiedAt = DateTime.now().toUtc();
    final isar = IsarService.instance;
    await isar.writeTxn(() => isar.artikelLocals.put(artikel));
  }

  static Future<void> delete(String id) async {
    if (kIsWeb) {
      try {
        await SupabaseService.client
            .from('artikel')
            .update({'is_deleted': true}).eq('id', id);
      } catch (_) {
        // Tabelle existiert noch nicht
      }
      return;
    }
    final isar = IsarService.instance;
    final artikel = await isar.artikelLocals.get(int.parse(id));
    if (artikel != null) {
      artikel.isDeleted = true;
      artikel.isSynced = false;
      artikel.lastModifiedAt = DateTime.now().toUtc();
      await isar.writeTxn(() => isar.artikelLocals.put(artikel));
    }
  }
}
