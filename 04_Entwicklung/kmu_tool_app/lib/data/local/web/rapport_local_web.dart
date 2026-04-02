class RapportLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String auftragId = '';
  String userId = '';
  DateTime datum = DateTime.now();
  String? beschreibung;
  String status = 'entwurf';
  DateTime? createdAt;
  DateTime? updatedAt;
}
