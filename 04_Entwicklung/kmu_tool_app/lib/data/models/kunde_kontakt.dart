class KundeKontakt {
  final String id;
  final String kundeId;
  final String vorname;
  final String nachname;
  final String? funktion;
  final String? telefon;
  final String? email;
  final String anrede;
  final String rolle;
  final String? notizen;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  KundeKontakt({
    required this.id,
    required this.kundeId,
    required this.vorname,
    required this.nachname,
    this.funktion,
    this.telefon,
    this.email,
    this.anrede = 'sie',
    this.rolle = 'mitarbeiter',
    this.notizen,
    this.createdAt,
    this.updatedAt,
  });

  factory KundeKontakt.fromJson(Map<String, dynamic> json) {
    return KundeKontakt(
      id: json['id'],
      kundeId: json['kunde_id'],
      vorname: json['vorname'] ?? '',
      nachname: json['nachname'] ?? '',
      funktion: json['funktion'],
      telefon: json['telefon'],
      email: json['email'],
      anrede: json['anrede'] ?? 'sie',
      rolle: json['rolle'] ?? 'mitarbeiter',
      notizen: json['notizen'],
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
      'kunde_id': kundeId,
      'vorname': vorname,
      'nachname': nachname,
      'funktion': funktion,
      'telefon': telefon,
      'email': email,
      'anrede': anrede,
      'rolle': rolle,
      'notizen': notizen,
    };
  }

  String get vollerName => '$vorname $nachname'.trim();
}
