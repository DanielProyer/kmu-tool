class RechnungsPosition {
  final String id;
  final String rechnungId;
  final int positionNr;
  final String bezeichnung;
  final double menge;
  final String einheit;
  final double einheitspreis;
  final double betrag; // computed by DB but we receive it
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RechnungsPosition({
    required this.id,
    required this.rechnungId,
    required this.positionNr,
    required this.bezeichnung,
    required this.menge,
    required this.einheit,
    required this.einheitspreis,
    this.betrag = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory RechnungsPosition.fromJson(Map<String, dynamic> json) {
    return RechnungsPosition(
      id: json['id'] as String,
      rechnungId: json['rechnung_id'] as String,
      positionNr: json['position_nr'] as int,
      bezeichnung: json['bezeichnung'] as String,
      menge: (json['menge'] as num?)?.toDouble() ?? 0,
      einheit: json['einheit'] as String,
      einheitspreis: (json['einheitspreis'] as num?)?.toDouble() ?? 0,
      betrag: (json['betrag'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// toJson does NOT include betrag - it is GENERATED in the database.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rechnung_id': rechnungId,
      'position_nr': positionNr,
      'bezeichnung': bezeichnung,
      'menge': menge,
      'einheit': einheit,
      'einheitspreis': einheitspreis,
    };
  }
}
