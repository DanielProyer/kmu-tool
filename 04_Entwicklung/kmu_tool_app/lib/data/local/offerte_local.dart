import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:isar/isar.dart';

part 'offerte_local.g.dart';

@collection
class OfferteLocal {
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
  String? offertNr;
  late DateTime datum;
  DateTime? gueltigBis;
  String status = 'entwurf';
  double totalNetto = 0.0;
  double mwstSatz = 8.1;
  double mwstBetrag = 0.0;
  double totalBrutto = 0.0;
  String? bemerkung;
  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
