class KundeLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String userId = '';
  String? firma;
  String? vorname;
  String nachname = '';
  String? strasse;
  String? plz;
  String? ort;
  String? telefon;
  String? email;
  String? notizen;
  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
