class Lagerbestand {
  final String id;
  final String userId;
  final String artikelId;
  final String lagerortId;
  final double menge;
  final double reserviert;
  final DateTime? updatedAt;

  // Joined fields
  final String? lagerortBezeichnung;
  final String? lagerortTyp;

  Lagerbestand({
    required this.id,
    required this.userId,
    required this.artikelId,
    required this.lagerortId,
    this.menge = 0,
    this.reserviert = 0,
    this.updatedAt,
    this.lagerortBezeichnung,
    this.lagerortTyp,
  });

  double get verfuegbar => menge - reserviert;

  factory Lagerbestand.fromJson(Map<String, dynamic> json) {
    String? bezeichnung;
    String? typ;
    if (json['lagerorte'] is Map) {
      bezeichnung = (json['lagerorte'] as Map)['bezeichnung'] as String?;
      typ = (json['lagerorte'] as Map)['typ'] as String?;
    }
    return Lagerbestand(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      artikelId: json['artikel_id'] as String,
      lagerortId: json['lagerort_id'] as String,
      menge: (json['menge'] as num?)?.toDouble() ?? 0,
      reserviert: (json['reserviert'] as num?)?.toDouble() ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lagerortBezeichnung: bezeichnung,
      lagerortTyp: typ,
    );
  }
}
