class Bestellposition {
  final String id;
  final String userId;
  final String bestellungId;
  final String artikelId;
  final double menge;
  final double einzelpreis;
  final double gelieferteMenge;
  final String? bemerkung;
  final DateTime? createdAt;

  // Joined fields
  final String? artikelBezeichnung;
  final String? artikelArtikelnummer;
  final String? artikelEinheit;

  Bestellposition({
    required this.id,
    required this.userId,
    required this.bestellungId,
    required this.artikelId,
    required this.menge,
    this.einzelpreis = 0,
    this.gelieferteMenge = 0,
    this.bemerkung,
    this.createdAt,
    this.artikelBezeichnung,
    this.artikelArtikelnummer,
    this.artikelEinheit,
  });

  factory Bestellposition.fromJson(Map<String, dynamic> json) {
    String? artikelBez;
    String? artikelNr;
    String? artikelEinheit;

    if (json['artikel'] is Map) {
      final a = json['artikel'] as Map;
      artikelBez = a['bezeichnung'] as String?;
      artikelNr = a['artikelnummer'] as String?;
      artikelEinheit = a['einheit'] as String?;
    }

    return Bestellposition(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bestellungId: json['bestellung_id'] as String,
      artikelId: json['artikel_id'] as String,
      menge: (json['menge'] as num?)?.toDouble() ?? 0,
      einzelpreis: (json['einzelpreis'] as num?)?.toDouble() ?? 0,
      gelieferteMenge: (json['gelieferte_menge'] as num?)?.toDouble() ?? 0,
      bemerkung: json['bemerkung'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      artikelBezeichnung: artikelBez,
      artikelArtikelnummer: artikelNr,
      artikelEinheit: artikelEinheit,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bestellung_id': bestellungId,
      'artikel_id': artikelId,
      'menge': menge,
      'einzelpreis': einzelpreis,
      'gelieferte_menge': gelieferteMenge,
      'bemerkung': bemerkung,
    };
  }

  double get gesamtpreis => menge * einzelpreis;
  double get offeneMenge => menge - gelieferteMenge;
  bool get vollstaendigGeliefert => gelieferteMenge >= menge;
}
