import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

part 'auftrag_local.g.dart';

@collection
class AuftragLocal {
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
  late String kundeId;
  String? offerteId;
  String? auftragsNr;
  String status = 'offen';
  String? beschreibung;
  DateTime? geplantVon;
  DateTime? geplantBis;
  String auftragTyp = 'einmalig';
  String? intervall;
  DateTime? naechsteAusfuehrung;
  int vorlaufTage = 7;
  String? periodischBezeichnung;
  String? parentAuftragId;
  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
