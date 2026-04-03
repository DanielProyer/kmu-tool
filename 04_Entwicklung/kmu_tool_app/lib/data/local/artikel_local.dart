import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

part 'artikel_local.g.dart';

@collection
class ArtikelLocal {
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
  String? artikelNr;
  late String bezeichnung;
  String kategorie = 'material'; // material, werkzeug, verbrauch
  String? einheit;
  double einkaufspreis = 0;
  double verkaufspreis = 0;
  double lagerbestand = 0;
  double? mindestbestand;
  String? lieferant;
  String? notizen;
  String? materialTyp;
  int? aufwandkonto;
  String? mwstCode;
  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
