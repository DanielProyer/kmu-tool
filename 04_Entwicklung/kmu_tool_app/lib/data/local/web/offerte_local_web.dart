class OfferteLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String userId = '';
  String kundeId = '';
  String? offertNr;
  DateTime datum = DateTime.now();
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
