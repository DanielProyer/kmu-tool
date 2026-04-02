class Rechnung {
  final String id;
  final String userId;
  final String kundeId;
  final String? auftragId;
  final String rechnungsNr;
  final DateTime datum;
  final DateTime faelligAm;
  final String status; // entwurf, gesendet, bezahlt, storniert, gemahnt
  final double totalNetto;
  final double mwstSatz;
  final double mwstBetrag;
  final double totalBrutto;
  final String? qrReferenz;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rechnung({
    required this.id,
    required this.userId,
    required this.kundeId,
    this.auftragId,
    required this.rechnungsNr,
    required this.datum,
    required this.faelligAm,
    required this.status,
    required this.totalNetto,
    required this.mwstSatz,
    required this.mwstBetrag,
    required this.totalBrutto,
    this.qrReferenz,
    this.createdAt,
    this.updatedAt,
  });

  factory Rechnung.fromJson(Map<String, dynamic> json) {
    return Rechnung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      kundeId: json['kunde_id'] as String,
      auftragId: json['auftrag_id'] as String?,
      rechnungsNr: json['rechnungs_nr'] as String,
      datum: DateTime.parse(json['datum'] as String),
      faelligAm: DateTime.parse(json['faellig_am'] as String),
      status: json['status'] as String,
      totalNetto: (json['total_netto'] as num?)?.toDouble() ?? 0,
      mwstSatz: (json['mwst_satz'] as num?)?.toDouble() ?? 0,
      mwstBetrag: (json['mwst_betrag'] as num?)?.toDouble() ?? 0,
      totalBrutto: (json['total_brutto'] as num?)?.toDouble() ?? 0,
      qrReferenz: json['qr_referenz'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kunde_id': kundeId,
      'auftrag_id': auftragId,
      'rechnungs_nr': rechnungsNr,
      'datum': datum.toIso8601String(),
      'faellig_am': faelligAm.toIso8601String(),
      'status': status,
      'total_netto': totalNetto,
      'mwst_satz': mwstSatz,
      'mwst_betrag': mwstBetrag,
      'total_brutto': totalBrutto,
      'qr_referenz': qrReferenz,
    };
  }
}
