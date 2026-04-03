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
  String? hausnummer;
  String? plz;
  String? ort;
  String? telefon;
  String? email;
  String? notizen;

  // Rechnungsadresse (falls abweichend)
  bool reAbweichend = false;
  String? reFirma;
  String? reVorname;
  String? reNachname;
  String? reStrasse;
  String? reHausnummer;
  String? rePlz;
  String? reOrt;
  String? reEmail;

  // Rechnungsstellung
  String rechnungsstellung = 'email'; // email, post, bar, abgabe_vor_ort

  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
