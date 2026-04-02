import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

part 'kunde_local.g.dart';

@collection
class KundeLocal {
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
  String? firma;
  String? vorname;
  late String nachname;
  String? strasse;
  String? plz;
  String? ort;
  String? telefon;
  String? email;
  String? notizen;
  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
