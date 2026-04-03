class Lieferant {
  final String id;
  final String userId;
  final String firma;
  final String? kontaktperson;
  final String? strasse;
  final String? plz;
  final String? ort;
  final String? telefon;
  final String? email;
  final String? website;
  final int zahlungsfristTage;
  final String? notizen;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lieferant({
    required this.id,
    required this.userId,
    required this.firma,
    this.kontaktperson,
    this.strasse,
    this.plz,
    this.ort,
    this.telefon,
    this.email,
    this.website,
    this.zahlungsfristTage = 30,
    this.notizen,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Lieferant.fromJson(Map<String, dynamic> json) {
    return Lieferant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      firma: json['firma'] as String,
      kontaktperson: json['kontaktperson'] as String?,
      strasse: json['strasse'] as String?,
      plz: json['plz'] as String?,
      ort: json['ort'] as String?,
      telefon: json['telefon'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      zahlungsfristTage: json['zahlungsfrist_tage'] as int? ?? 30,
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
      'firma': firma,
      'kontaktperson': kontaktperson,
      'strasse': strasse,
      'plz': plz,
      'ort': ort,
      'telefon': telefon,
      'email': email,
      'website': website,
      'zahlungsfrist_tage': zahlungsfristTage,
      'notizen': notizen,
      'is_deleted': isDeleted,
    };
  }

  String get adresseEinzeilig {
    final parts = <String>[];
    if (strasse != null && strasse!.isNotEmpty) parts.add(strasse!);
    if (plz != null && ort != null) {
      parts.add('$plz $ort');
    } else if (ort != null && ort!.isNotEmpty) {
      parts.add(ort!);
    }
    return parts.join(', ');
  }
}
