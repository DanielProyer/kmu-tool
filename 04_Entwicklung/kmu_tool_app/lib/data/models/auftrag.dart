class Auftrag {
  final String id;
  final String userId;
  final String kundeId;
  final String? offerteId;
  final String? auftragsNr;
  final String status;
  final String? beschreibung;
  final DateTime? geplantVon;
  final DateTime? geplantBis;
  final String auftragTyp;
  final String? intervall;
  final DateTime? naechsteAusfuehrung;
  final int vorlaufTage;
  final String? periodischBezeichnung;
  final String? parentAuftragId;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Auftrag({
    required this.id,
    required this.userId,
    required this.kundeId,
    this.offerteId,
    this.auftragsNr,
    this.status = 'offen',
    this.beschreibung,
    this.geplantVon,
    this.geplantBis,
    this.auftragTyp = 'einmalig',
    this.intervall,
    this.naechsteAusfuehrung,
    this.vorlaufTage = 7,
    this.periodischBezeichnung,
    this.parentAuftragId,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Auftrag.fromJson(Map<String, dynamic> json) {
    return Auftrag(
      id: json['id'],
      userId: json['user_id'],
      kundeId: json['kunde_id'],
      offerteId: json['offerte_id'],
      auftragsNr: json['auftrags_nr'],
      status: json['status'] ?? 'offen',
      beschreibung: json['beschreibung'],
      geplantVon: json['geplant_von'] != null
          ? DateTime.parse(json['geplant_von'])
          : null,
      geplantBis: json['geplant_bis'] != null
          ? DateTime.parse(json['geplant_bis'])
          : null,
      auftragTyp: json['auftrag_typ'] ?? 'einmalig',
      intervall: json['intervall'],
      naechsteAusfuehrung: json['naechste_ausfuehrung'] != null
          ? DateTime.parse(json['naechste_ausfuehrung'])
          : null,
      vorlaufTage: json['vorlauf_tage'] ?? 7,
      periodischBezeichnung: json['periodisch_bezeichnung'],
      parentAuftragId: json['parent_auftrag_id'],
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
      'offerte_id': offerteId,
      'auftrags_nr': auftragsNr,
      'status': status,
      'beschreibung': beschreibung,
      'geplant_von': geplantVon?.toIso8601String().split('T').first,
      'geplant_bis': geplantBis?.toIso8601String().split('T').first,
      'auftrag_typ': auftragTyp,
      'intervall': intervall,
      'naechste_ausfuehrung':
          naechsteAusfuehrung?.toIso8601String().split('T').first,
      'vorlauf_tage': vorlaufTage,
      'periodisch_bezeichnung': periodischBezeichnung,
      'parent_auftrag_id': parentAuftragId,
      'is_deleted': isDeleted,
    };
  }
}
