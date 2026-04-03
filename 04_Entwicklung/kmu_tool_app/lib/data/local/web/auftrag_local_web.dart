class AuftragLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String userId = '';
  String kundeId = '';
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
