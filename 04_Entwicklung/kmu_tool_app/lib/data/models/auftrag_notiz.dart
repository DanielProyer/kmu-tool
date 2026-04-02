class AuftragNotiz {
  final String id;
  final String auftragId;
  final String userId;
  final String typ; // text, foto, pdf
  final String? inhalt;
  final String? dateiPfad;
  final String? dateiName;
  final int? dateiGroesse;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AuftragNotiz({
    required this.id,
    required this.auftragId,
    required this.userId,
    this.typ = 'text',
    this.inhalt,
    this.dateiPfad,
    this.dateiName,
    this.dateiGroesse,
    this.createdAt,
    this.updatedAt,
  });

  factory AuftragNotiz.fromJson(Map<String, dynamic> json) {
    return AuftragNotiz(
      id: json['id'] as String,
      auftragId: json['auftrag_id'] as String,
      userId: json['user_id'] as String,
      typ: json['typ'] as String? ?? 'text',
      inhalt: json['inhalt'] as String?,
      dateiPfad: json['datei_pfad'] as String?,
      dateiName: json['datei_name'] as String?,
      dateiGroesse: json['datei_groesse'] as int?,
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
      'typ': typ,
      'inhalt': inhalt,
      'datei_pfad': dateiPfad,
      'datei_name': dateiName,
      'datei_groesse': dateiGroesse,
    };
  }
}
