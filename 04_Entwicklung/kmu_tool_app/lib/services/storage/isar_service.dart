import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kmu_tool_app/data/local/kunde_local.dart';
import 'package:kmu_tool_app/data/local/kunde_kontakt_local.dart';
import 'package:kmu_tool_app/data/local/offerte_local.dart';
import 'package:kmu_tool_app/data/local/offert_position_local.dart';
import 'package:kmu_tool_app/data/local/auftrag_local.dart';
import 'package:kmu_tool_app/data/local/zeiterfassung_local.dart';
import 'package:kmu_tool_app/data/local/rapport_local.dart';
import 'package:kmu_tool_app/data/local/sync_meta_local.dart';
import 'package:kmu_tool_app/data/local/artikel_local.dart';

class IsarService {
  static Isar? _instance;

  static Isar get instance {
    if (_instance == null) {
      throw StateError(
          'Isar not initialized. Call IsarService.initialize() first.');
    }
    return _instance!;
  }

  static Future<void> initialize() async {
    if (_instance != null) return;

    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [
        KundeLocalSchema,
        KundeKontaktLocalSchema,
        OfferteLocalSchema,
        OffertPositionLocalSchema,
        AuftragLocalSchema,
        ZeiterfassungLocalSchema,
        RapportLocalSchema,
        SyncMetaLocalSchema,
        ArtikelLocalSchema,
      ],
      directory: dir.path,
    );
  }

  static Future<T> writeTxn<T>(Future<T> Function() callback) =>
      instance.writeTxn(callback);

  static Future<void> close() async {
    await _instance?.close();
    _instance = null;
  }
}
