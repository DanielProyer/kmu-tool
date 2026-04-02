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

  // Rechnungsadresse (falls abweichend)
  final bool reAbweichend;
  final String? reFirma;
  final String? reVorname;
  final String? reNachname;
  final String? reStrasse;
  final String? rePlz;
  final String? reOrt;
  final String? reEmail;

  // Rechnungsstellung
  final String rechnungsstellung;

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
    this.reAbweichend = false,
    this.reFirma,
    this.reVorname,
    this.reNachname,
    this.reStrasse,
    this.rePlz,
    this.reOrt,
    this.reEmail,
    this.rechnungsstellung = 'email',
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
      reAbweichend: json['re_abweichend'] ?? false,
      reFirma: json['re_firma'],
      reVorname: json['re_vorname'],
      reNachname: json['re_nachname'],
      reStrasse: json['re_strasse'],
      rePlz: json['re_plz'],
      reOrt: json['re_ort'],
      reEmail: json['re_email'],
      rechnungsstellung: json['rechnungsstellung'] ?? 'email',
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
      're_abweichend': reAbweichend,
      're_firma': reFirma,
      're_vorname': reVorname,
      're_nachname': reNachname,
      're_strasse': reStrasse,
      're_plz': rePlz,
      're_ort': reOrt,
      're_email': reEmail,
      'rechnungsstellung': rechnungsstellung,
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
