class AdminDatenmigration {
  final String id;
  final String kundeProfilId;
  final String typ; // excel, papier, datenbank, andere
  final String? quellBeschreibung;
  final List<String> module;
  final String status; // geplant, in_bearbeitung, abgeschlossen, fehler
  final int fortschritt;
  final String? ergebnisZusammenfassung;
  final String? notizen;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined
  final String? kundeFirma;

  AdminDatenmigration({
    required this.id,
    required this.kundeProfilId,
    required this.typ,
    this.quellBeschreibung,
    this.module = const [],
    this.status = 'geplant',
    this.fortschritt = 0,
    this.ergebnisZusammenfassung,
    this.notizen,
    this.createdAt,
    this.updatedAt,
    this.kundeFirma,
  });

  factory AdminDatenmigration.fromJson(Map<String, dynamic> json) {
    String? firma;
    if (json['admin_kundenprofile'] is Map) {
      firma = (json['admin_kundenprofile'] as Map)['firma_name'] as String?;
    }
    List<String> mod = [];
    if (json['module'] is List) {
      mod = (json['module'] as List).cast<String>();
    }
    return AdminDatenmigration(
      id: json['id'] as String,
      kundeProfilId: json['kunde_profil_id'] as String,
      typ: json['typ'] as String,
      quellBeschreibung: json['quell_beschreibung'] as String?,
      module: mod,
      status: json['status'] as String? ?? 'geplant',
      fortschritt: json['fortschritt'] as int? ?? 0,
      ergebnisZusammenfassung: json['ergebnis_zusammenfassung'] as String?,
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
      'typ': typ,
      'quell_beschreibung': quellBeschreibung,
      'module': module,
      'status': status,
      'fortschritt': fortschritt,
      'ergebnis_zusammenfassung': ergebnisZusammenfassung,
      'notizen': notizen,
    };
  }

  String get typLabel {
    switch (typ) {
      case 'excel':
        return 'Excel-Import';
      case 'papier':
        return 'Papier-Digitalisierung';
      case 'datenbank':
        return 'Datenbank-Migration';
      case 'andere':
        return 'Andere';
      default:
        return typ;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'geplant':
        return 'Geplant';
      case 'in_bearbeitung':
        return 'In Bearbeitung';
      case 'abgeschlossen':
        return 'Abgeschlossen';
      case 'fehler':
        return 'Fehler';
      default:
        return status;
    }
  }
}
