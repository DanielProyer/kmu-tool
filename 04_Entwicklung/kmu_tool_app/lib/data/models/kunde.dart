class Kunde {
  final String id;
  final String userId;
  final String? firma;
  final String? vorname;
  final String nachname;
  final String? strasse;
  final String? plz;
  final String? ort;
  final String? telefon;
  final String? email;
  final String? notizen;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Kunde({
    required this.id,
    required this.userId,
    this.firma,
    this.vorname,
    required this.nachname,
    this.strasse,
    this.plz,
    this.ort,
    this.telefon,
    this.email,
    this.notizen,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Kunde.fromJson(Map<String, dynamic> json) {
    return Kunde(
      id: json['id'],
      userId: json['user_id'],
      firma: json['firma'],
      vorname: json['vorname'],
      nachname: json['nachname'] ?? '',
      strasse: json['strasse'],
      plz: json['plz'],
      ort: json['ort'],
      telefon: json['telefon'],
      email: json['email'],
      notizen: json['notizen'],
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
      'firma': firma,
      'vorname': vorname,
      'nachname': nachname,
      'strasse': strasse,
      'plz': plz,
      'ort': ort,
      'telefon': telefon,
      'email': email,
      'notizen': notizen,
      'is_deleted': isDeleted,
    };
  }

  String get displayName => firma ?? '$vorname $nachname'.trim();

  String get vollstaendigeAdresse {
    final parts = [strasse, plz, ort]
        .where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }
}
