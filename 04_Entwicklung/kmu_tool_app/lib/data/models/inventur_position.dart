class InventurPosition {
  final String id;
  final String userId;
  final String inventurId;
  final String artikelId;
  final String lagerortId;
  final double sollBestand;
  final double? istBestand;
  final double? differenz; // Generated column
  final double bewertungspreis;
  final bool gezaehlt;
  final String? bemerkung;
  final DateTime? createdAt;

  // Joined fields
  final String? artikelBezeichnung;
  final String? artikelArtikelnummer;
  final String? artikelEinheit;
  final String? lagerortBezeichnung;

  InventurPosition({
    required this.id,
    required this.userId,
    required this.inventurId,
    required this.artikelId,
    required this.lagerortId,
    this.sollBestand = 0,
    this.istBestand,
    this.differenz,
    this.bewertungspreis = 0,
    this.gezaehlt = false,
    this.bemerkung,
    this.createdAt,
    this.artikelBezeichnung,
    this.artikelArtikelnummer,
    this.artikelEinheit,
    this.lagerortBezeichnung,
  });

  factory InventurPosition.fromJson(Map<String, dynamic> json) {
    String? artikelBez;
    String? artikelNr;
    String? artikelEinheit;
    String? lagerortBez;

    if (json['artikel'] is Map) {
      final a = json['artikel'] as Map;
      artikelBez = a['bezeichnung'] as String?;
      artikelNr = a['artikelnummer'] as String?;
      artikelEinheit = a['einheit'] as String?;
    }
    if (json['lagerorte'] is Map) {
      lagerortBez = (json['lagerorte'] as Map)['bezeichnung'] as String?;
    }

    return InventurPosition(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      inventurId: json['inventur_id'] as String,
      artikelId: json['artikel_id'] as String,
      lagerortId: json['lagerort_id'] as String,
      sollBestand: (json['soll_bestand'] as num?)?.toDouble() ?? 0,
      istBestand: (json['ist_bestand'] as num?)?.toDouble(),
      differenz: (json['differenz'] as num?)?.toDouble(),
      bewertungspreis: (json['bewertungspreis'] as num?)?.toDouble() ?? 0,
      gezaehlt: json['gezaehlt'] as bool? ?? false,
      bemerkung: json['bemerkung'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      artikelBezeichnung: artikelBez,
      artikelArtikelnummer: artikelNr,
      artikelEinheit: artikelEinheit,
      lagerortBezeichnung: lagerortBez,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'inventur_id': inventurId,
      'artikel_id': artikelId,
      'lagerort_id': lagerortId,
      'soll_bestand': sollBestand,
      'ist_bestand': istBestand,
      'bewertungspreis': bewertungspreis,
      'gezaehlt': gezaehlt,
      'bemerkung': bemerkung,
    };
  }

  double get wertDifferenz => (differenz ?? 0) * bewertungspreis;
  bool get hatAbweichung => differenz != null && differenz != 0;
}
