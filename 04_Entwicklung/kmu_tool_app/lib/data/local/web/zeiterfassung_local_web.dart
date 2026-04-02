class ZeiterfassungLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String userId = '';
  String auftragId = '';
  DateTime datum = DateTime.now();
  String? startZeit;
  String? endZeit;
  int pauseMinuten = 0;
  int? dauerMinuten;
  String? beschreibung;
  DateTime? createdAt;
  DateTime? updatedAt;
}
