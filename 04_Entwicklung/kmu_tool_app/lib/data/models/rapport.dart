class Rapport {
  final String id;
  final String auftragId;
  final String userId;
  final DateTime datum;
  final String? beschreibung;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Rapport({
    required this.id,
    required this.auftragId,
    required this.userId,
    required this.datum,
    this.beschreibung,
    this.status = 'entwurf',
    this.createdAt,
    this.updatedAt,
  });

  factory Rapport.fromJson(Map<String, dynamic> json) {
    return Rapport(
      id: json['id'],
      auftragId: json['auftrag_id'],
      userId: json['user_id'],
      datum: DateTime.parse(json['datum']),
      beschreibung: json['beschreibung'],
      status: json['status'] ?? 'entwurf',
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
      'auftrag_id': auftragId,
      'user_id': userId,
      'datum': datum.toIso8601String().split('T').first,
      'beschreibung': beschreibung,
      'status': status,
    };
  }
}
