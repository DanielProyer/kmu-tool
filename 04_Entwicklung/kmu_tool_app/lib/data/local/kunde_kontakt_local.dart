import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

part 'kunde_kontakt_local.g.dart';

@collection
class KundeKontaktLocal {
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
  late String kundeId;
  late String vorname;
  late String nachname;
  String? funktion;
  String? telefon;
  String? email;
  String anrede = 'sie'; // sie, du
  String rolle = 'mitarbeiter'; // geschaeftsfuehrer, inhaber, bauleiter, etc.
  String? notizen;
  DateTime? createdAt;
  DateTime? updatedAt;
}
