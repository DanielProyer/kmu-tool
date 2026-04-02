class KundeKontaktLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String kundeId = '';
  String vorname = '';
  String nachname = '';
  String? funktion;
  String? telefon;
  String? email;
  String anrede = 'sie'; // sie, du
  String rolle = 'mitarbeiter'; // inhaber, geschaeftsfuehrer, projektleiter, mitarbeiter, sonstiges
  String? notizen;
  DateTime? createdAt;
  DateTime? updatedAt;
}
