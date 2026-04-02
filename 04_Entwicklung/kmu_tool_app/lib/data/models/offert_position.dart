class OffertPosition {
  final String id;
  final String offerteId;
  final int positionNr;
  final String bezeichnung;
  final double menge;
  final String? einheit;
  final double einheitspreis;
  final double betrag;
  final String typ; // arbeit, material
  final String? artikelId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OffertPosition({
    required this.id,
    required this.offerteId,
    this.positionNr = 1,
    required this.bezeichnung,
    this.menge = 1.0,
    this.einheit,
    this.einheitspreis = 0.0,
    this.betrag = 0.0,
    this.typ = 'arbeit',
    this.artikelId,
    this.createdAt,
    this.updatedAt,
  });

  factory OffertPosition.fromJson(Map<String, dynamic> json) {
    return OffertPosition(
      id: json['id'],
      offerteId: json['offerte_id'],
      positionNr: json['position_nr'] ?? 1,
      bezeichnung: json['bezeichnung'] ?? '',
      menge: (json['menge'] ?? 1).toDouble(),
      einheit: json['einheit'],
      einheitspreis: (json['einheitspreis'] ?? 0).toDouble(),
      betrag: (json['betrag'] ?? 0).toDouble(),
      typ: json['typ'] ?? 'arbeit',
      artikelId: json['artikel_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'offerte_id': offerteId,
      'position_nr': positionNr,
      'bezeichnung': bezeichnung,
      'menge': menge,
      'einheit': einheit,
      'einheitspreis': einheitspreis,
      'betrag': betrag,
      // Migration 013 Spalten - erst senden wenn Migration ausgefuehrt:
      // 'typ': typ,
      // 'artikel_id': artikelId,
    };
  }

  bool get isMaterial => typ == 'material';
  bool get isArbeit => typ == 'arbeit';
}
