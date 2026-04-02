class OffertPositionLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String offerteId = '';
  int positionNr = 1;
  String bezeichnung = '';
  double menge = 1.0;
  String? einheit;
  double einheitspreis = 0.0;
  double betrag = 0.0;
  DateTime? createdAt;
  DateTime? updatedAt;
}
