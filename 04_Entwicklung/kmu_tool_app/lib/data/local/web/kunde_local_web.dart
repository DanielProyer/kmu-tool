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
  // Rechnungsadresse
  bool reAbweichend = false;
  String? reFirma;
  String? reVorname;
  String? reNachname;
  String? reStrasse;
  String? rePlz;
  String? reOrt;
  String? reEmail;
  String rechnungsstellung = 'email'; // email, post, beides
  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
