class AdminRechnung {
  final String id;
  final String kundeProfilId;
  final String rechnungsNr;
  final DateTime? periodeVon;
  final DateTime? periodeBis;
  final String? planBezeichnung;
  final double betrag;
  final double mwstSatz;
  final double mwstBetrag;
  final double total;
  final String status; // offen, bezahlt, storniert, gemahnt
  final DateTime? bezahltAm;
  final DateTime? faelligAm;
  final String? notizen;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined
  final String? kundeFirma;

  AdminRechnung({
    required this.id,
    required this.kundeProfilId,
    required this.rechnungsNr,
    this.periodeVon,
    this.periodeBis,
    this.planBezeichnung,
    this.betrag = 0,
    this.mwstSatz = 8.1,
    this.mwstBetrag = 0,
    this.total = 0,
    this.status = 'offen',
    this.bezahltAm,
    this.faelligAm,
    this.notizen,
    this.createdAt,
    this.updatedAt,
    this.kundeFirma,
  });

  factory AdminRechnung.fromJson(Map<String, dynamic> json) {
    String? firma;
    if (json['admin_kundenprofile'] is Map) {
      firma = (json['admin_kundenprofile'] as Map)['firma_name'] as String?;
    }
    return AdminRechnung(
      id: json['id'] as String,
      kundeProfilId: json['kunde_profil_id'] as String,
      rechnungsNr: json['rechnungs_nr'] as String,
      periodeVon: json['periode_von'] != null
          ? DateTime.parse(json['periode_von'] as String)
          : null,
      periodeBis: json['periode_bis'] != null
          ? DateTime.parse(json['periode_bis'] as String)
          : null,
      planBezeichnung: json['plan_bezeichnung'] as String?,
      betrag: (json['betrag'] as num?)?.toDouble() ?? 0,
      mwstSatz: (json['mwst_satz'] as num?)?.toDouble() ?? 8.1,
      mwstBetrag: (json['mwst_betrag'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'offen',
      bezahltAm: json['bezahlt_am'] != null
          ? DateTime.parse(json['bezahlt_am'] as String)
          : null,
      faelligAm: json['faellig_am'] != null
          ? DateTime.parse(json['faellig_am'] as String)
          : null,
      notizen: json['notizen'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      kundeFirma: firma,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kunde_profil_id': kundeProfilId,
      'rechnungs_nr': rechnungsNr,
      'periode_von': periodeVon?.toIso8601String().split('T').first,
      'periode_bis': periodeBis?.toIso8601String().split('T').first,
      'plan_bezeichnung': planBezeichnung,
      'betrag': betrag,
      'mwst_satz': mwstSatz,
      'mwst_betrag': mwstBetrag,
      'total': total,
      'status': status,
      'bezahlt_am': bezahltAm?.toIso8601String(),
      'faellig_am': faelligAm?.toIso8601String().split('T').first,
      'notizen': notizen,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'offen':
        return 'Offen';
      case 'bezahlt':
        return 'Bezahlt';
      case 'storniert':
        return 'Storniert';
      case 'gemahnt':
        return 'Gemahnt';
      default:
        return status;
    }
  }
}
