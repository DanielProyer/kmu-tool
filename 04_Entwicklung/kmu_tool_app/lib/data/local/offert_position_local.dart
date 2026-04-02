import 'package:isar/isar.dart';

part 'offert_position_local.g.dart';

@collection
class OffertPositionLocal {
  Id id = Isar.autoIncrement;

  // Supabase Sync
  @Index()
  String? serverId;
  @Index()
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  late String offerteId;
  int positionNr = 1;
  late String bezeichnung;
  double menge = 1.0;
  String? einheit;
  double einheitspreis = 0.0;
  double betrag = 0.0;
  String typ = 'arbeit'; // arbeit, material
  String? artikelId;
  DateTime? createdAt;
  DateTime? updatedAt;
}
