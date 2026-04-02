import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

part 'zeiterfassung_local.g.dart';

@collection
class ZeiterfassungLocal {
  Id id = Isar.autoIncrement;

  @ignore
  String get routeId => kIsWeb ? serverId! : id.toString();

  // Supabase Sync
  @Index()
  String? serverId;
  @Index()
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  late String userId;
  late String auftragId;
  late DateTime datum;
  String? startZeit;
  String? endZeit;
  int pauseMinuten = 0;
  int? dauerMinuten;
  String? beschreibung;
  DateTime? createdAt;
  DateTime? updatedAt;
}
