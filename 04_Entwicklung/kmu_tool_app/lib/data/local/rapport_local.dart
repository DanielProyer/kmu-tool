import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

part 'rapport_local.g.dart';

@collection
class RapportLocal {
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
  late String auftragId;
  late String userId;
  late DateTime datum;
  String? beschreibung;
  String status = 'entwurf';
  DateTime? createdAt;
  DateTime? updatedAt;
}
