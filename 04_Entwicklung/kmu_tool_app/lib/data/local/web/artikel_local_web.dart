class ArtikelLocal {
  int id = 0;

  String get routeId => serverId!;

  // Supabase Sync
  String? serverId;
  bool isSynced = false;
  DateTime? lastModifiedAt;

  // Felder
  String userId = '';
  String? artikelNr;
  String bezeichnung = '';
  String kategorie = 'material';
  String? einheit;
  double einkaufspreis = 0;
  double verkaufspreis = 0;
  double lagerbestand = 0;
  double? mindestbestand;
  String? lieferant;
  String? notizen;
  String? materialTyp;
  int? aufwandkonto;
  String? mwstCode;
  bool isDeleted = false;
  DateTime? createdAt;
  DateTime? updatedAt;
}
