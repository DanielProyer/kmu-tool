class AuftragDatei {
  final String id;
  final String auftragId;
  final String userId;
  final String kategorie; // allgemein, plan, foto, vertrag, rechnung, sonstiges
  final String dateiPfad;
  final String dateiName;
  final String? dateiTyp;
  final int? dateiGroesse;
  final bool fuerKundeSichtbar;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuftragDatei({
    required this.id,
    required this.auftragId,
    required this.userId,
    this.kategorie = 'allgemein',
    required this.dateiPfad,
    required this.dateiName,
    this.dateiTyp,
    this.dateiGroesse,
    this.fuerKundeSichtbar = false,
    this.createdAt,
    this.updatedAt,
  });

  factory AuftragDatei.fromJson(Map<String, dynamic> json) {
    return AuftragDatei(
      id: json['id'] as String,
      auftragId: json['auftrag_id'] as String,
      userId: json['user_id'] as String,
      kategorie: json['kategorie'] as String? ?? 'allgemein',
      dateiPfad: json['datei_pfad'] as String,
      dateiName: json['datei_name'] as String,
      dateiTyp: json['datei_typ'] as String?,
      dateiGroesse: json['datei_groesse'] as int?,
      fuerKundeSichtbar: json['fuer_kunde_sichtbar'] as bool? ?? false,
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
      'auftrag_id': auftragId,
      'user_id': userId,
      'kategorie': kategorie,
      'datei_pfad': dateiPfad,
      'datei_name': dateiName,
      'datei_typ': dateiTyp,
      'datei_groesse': dateiGroesse,
      'fuer_kunde_sichtbar': fuerKundeSichtbar,
    };
  }

  String get kategorieLabel {
    switch (kategorie) {
      case 'plan':
        return 'Plan';
      case 'foto':
        return 'Foto';
      case 'vertrag':
        return 'Vertrag';
      case 'rechnung':
        return 'Rechnung';
      case 'sonstiges':
        return 'Sonstiges';
      default:
        return 'Allgemein';
    }
  }
}
