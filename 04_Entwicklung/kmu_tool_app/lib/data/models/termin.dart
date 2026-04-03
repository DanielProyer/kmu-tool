class Termin {
  final String id;
  final String userId;
  final String titel;
  final String? beschreibung;
  final DateTime datum;
  final String? startZeit; // HH:mm format
  final String? endZeit;
  final bool ganztaegig;
  final String? ort;
  final String? kundeId;
  final String? auftragId;
  final String typ; // termin, auftrag, service, erinnerung
  final String status; // geplant, bestaetigt, erledigt, abgesagt
  final String? farbe;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined
  final String? kundeBezeichnung;
  final String? auftragBezeichnung;

  Termin({
    required this.id,
    required this.userId,
    required this.titel,
    this.beschreibung,
    required this.datum,
    this.startZeit,
    this.endZeit,
    this.ganztaegig = false,
    this.ort,
    this.kundeId,
    this.auftragId,
    this.typ = 'termin',
    this.status = 'geplant',
    this.farbe,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.kundeBezeichnung,
    this.auftragBezeichnung,
  });

  factory Termin.fromJson(Map<String, dynamic> json) {
    String? kundeBezeichnung;
    if (json['kunden'] is Map) {
      final k = json['kunden'] as Map;
      kundeBezeichnung = k['firma'] as String? ??
          '${k['vorname'] ?? ''} ${k['nachname'] ?? ''}'.trim();
    }
    String? auftragBezeichnung;
    if (json['auftraege'] is Map) {
      auftragBezeichnung =
          (json['auftraege'] as Map)['auftrags_nr'] as String?;
    }

    return Termin(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      titel: json['titel'] as String? ?? '',
      beschreibung: json['beschreibung'] as String?,
      datum: DateTime.parse(json['datum'] as String),
      startZeit: json['start_zeit'] as String?,
      endZeit: json['end_zeit'] as String?,
      ganztaegig: json['ganztaegig'] as bool? ?? false,
      ort: json['ort'] as String?,
      kundeId: json['kunde_id'] as String?,
      auftragId: json['auftrag_id'] as String?,
      typ: json['typ'] as String? ?? 'termin',
      status: json['status'] as String? ?? 'geplant',
      farbe: json['farbe'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      kundeBezeichnung: kundeBezeichnung,
      auftragBezeichnung: auftragBezeichnung,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'titel': titel,
      'beschreibung': beschreibung,
      'datum': datum.toIso8601String().split('T')[0],
      'start_zeit': startZeit,
      'end_zeit': endZeit,
      'ganztaegig': ganztaegig,
      'ort': ort,
      'kunde_id': kundeId,
      'auftrag_id': auftragId,
      'typ': typ,
      'status': status,
      'farbe': farbe,
      'is_deleted': isDeleted,
    };
  }

  String get typLabel {
    switch (typ) {
      case 'termin': return 'Termin';
      case 'auftrag': return 'Auftrag';
      case 'service': return 'Service';
      case 'erinnerung': return 'Erinnerung';
      default: return typ;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'geplant': return 'Geplant';
      case 'bestaetigt': return 'Bestaetigt';
      case 'erledigt': return 'Erledigt';
      case 'abgesagt': return 'Abgesagt';
      default: return status;
    }
  }

  String get zeitAnzeige {
    if (ganztaegig) return 'Ganztaegig';
    if (startZeit != null && endZeit != null) return '$startZeit - $endZeit';
    if (startZeit != null) return 'Ab $startZeit';
    return '';
  }
}
