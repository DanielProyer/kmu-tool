class Mitarbeiter {
  final String id;
  final String userId;
  final String vorname;
  final String nachname;
  final String? telefon;
  final String? email;
  final String rolle; // geschaeftsfuehrer, vorarbeiter, geselle, lehrling, mitarbeiter, buero
  final String? strasse;
  final String? hausnummer;
  final String? plz;
  final String? ort;
  final String? ahvNummer;
  final double pensum; // 0.0 - 1.0 (100%)
  final String? notizen;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Mitarbeiter({
    required this.id,
    required this.userId,
    required this.vorname,
    required this.nachname,
    this.telefon,
    this.email,
    this.rolle = 'mitarbeiter',
    this.strasse,
    this.hausnummer,
    this.plz,
    this.ort,
    this.ahvNummer,
    this.pensum = 1.0,
    this.notizen,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Mitarbeiter.fromJson(Map<String, dynamic> json) {
    return Mitarbeiter(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vorname: json['vorname'] as String? ?? '',
      nachname: json['nachname'] as String? ?? '',
      telefon: json['telefon'] as String?,
      email: json['email'] as String?,
      rolle: json['rolle'] as String? ?? 'mitarbeiter',
      strasse: json['strasse'] as String?,
      hausnummer: json['hausnummer'] as String?,
      plz: json['plz'] as String?,
      ort: json['ort'] as String?,
      ahvNummer: json['ahv_nummer'] as String?,
      pensum: (json['pensum'] as num?)?.toDouble() ?? 1.0,
      notizen: json['notizen'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
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
      'id': id,
      'user_id': userId,
      'vorname': vorname,
      'nachname': nachname,
      'telefon': telefon,
      'email': email,
      'rolle': rolle,
      'strasse': strasse,
      'hausnummer': hausnummer,
      'plz': plz,
      'ort': ort,
      'ahv_nummer': ahvNummer,
      'pensum': pensum,
      'notizen': notizen,
      'is_deleted': isDeleted,
    };
  }

  String get displayName => '$vorname $nachname'.trim();

  String get rolleLabel {
    switch (rolle) {
      case 'geschaeftsfuehrer': return 'Geschaeftsfuehrer/in';
      case 'vorarbeiter': return 'Vorarbeiter/in';
      case 'geselle': return 'Geselle/Gesellin';
      case 'lehrling': return 'Lehrling';
      case 'mitarbeiter': return 'Mitarbeiter/in';
      case 'buero': return 'Buero';
      default: return rolle;
    }
  }

  String get strasseMitNr {
    final s = strasse ?? '';
    final h = hausnummer ?? '';
    return '$s $h'.trim();
  }
}
