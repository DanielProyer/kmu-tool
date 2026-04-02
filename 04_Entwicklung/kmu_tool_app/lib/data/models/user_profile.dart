class UserProfile {
  final String id;
  final String email;
  final String firmaName;
  final String rechtsform;
  final String? strasse;
  final String? plz;
  final String? ort;
  final String? telefon;
  final String? uidNummer;
  final String? iban;
  final String? bankName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.firmaName,
    required this.rechtsform,
    this.strasse,
    this.plz,
    this.ort,
    this.telefon,
    this.uidNummer,
    this.iban,
    this.bankName,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      firmaName: json['firma_name'] as String,
      rechtsform: json['rechtsform'] as String,
      strasse: json['strasse'] as String?,
      plz: json['plz'] as String?,
      ort: json['ort'] as String?,
      telefon: json['telefon'] as String?,
      uidNummer: json['uid_nummer'] as String?,
      iban: json['iban'] as String?,
      bankName: json['bank_name'] as String?,
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
      'email': email,
      'firma_name': firmaName,
      'rechtsform': rechtsform,
      'strasse': strasse,
      'plz': plz,
      'ort': ort,
      'telefon': telefon,
      'uid_nummer': uidNummer,
      'iban': iban,
      'bank_name': bankName,
    };
  }
}
