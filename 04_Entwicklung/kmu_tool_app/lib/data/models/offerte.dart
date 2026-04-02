class Offerte {
  final String id;
  final String userId;
  final String kundeId;
  final String? offertNr;
  final DateTime datum;
  final DateTime? gueltigBis;
  final String status;
  final double totalNetto;
  final double mwstSatz;
  final double mwstBetrag;
  final double totalBrutto;
  final String? bemerkung;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Offerte({
    required this.id,
    required this.userId,
    required this.kundeId,
    this.offertNr,
    required this.datum,
    this.gueltigBis,
    this.status = 'entwurf',
    this.totalNetto = 0.0,
    this.mwstSatz = 8.1,
    this.mwstBetrag = 0.0,
    this.totalBrutto = 0.0,
    this.bemerkung,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Offerte.fromJson(Map<String, dynamic> json) {
    return Offerte(
      id: json['id'],
      userId: json['user_id'],
      kundeId: json['kunde_id'],
      offertNr: json['offert_nr'],
      datum: DateTime.parse(json['datum']),
      gueltigBis: json['gueltig_bis'] != null
          ? DateTime.parse(json['gueltig_bis'])
          : null,
      status: json['status'] ?? 'entwurf',
      totalNetto: (json['total_netto'] ?? 0).toDouble(),
      mwstSatz: (json['mwst_satz'] ?? 8.1).toDouble(),
      mwstBetrag: (json['mwst_betrag'] ?? 0).toDouble(),
      totalBrutto: (json['total_brutto'] ?? 0).toDouble(),
      bemerkung: json['bemerkung'],
      isDeleted: json['is_deleted'] ?? false,
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
      'user_id': userId,
      'kunde_id': kundeId,
      'offert_nr': offertNr,
      'datum': datum.toIso8601String().split('T').first,
      'gueltig_bis': gueltigBis?.toIso8601String().split('T').first,
      'status': status,
      'total_netto': totalNetto,
      'mwst_satz': mwstSatz,
      'mwst_betrag': mwstBetrag,
      'total_brutto': totalBrutto,
      'bemerkung': bemerkung,
      'is_deleted': isDeleted,
    };
  }
}
