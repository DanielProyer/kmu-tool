class AdminKundenprofil {
  final String id;
  final String? userId;
  final String firmaName;
  final String? kontaktperson;
  final String? email;
  final String? telefon;
  final String? strasse;
  final String? hausnummer;
  final String? plz;
  final String? ort;
  final String status; // aktiv, inaktiv, gesperrt, test
  final String mwstMethode; // effektiv, saldosteuersatz
  final int anzahlMitarbeiter;
  final int anzahlFahrzeuge;
  final String? branche;
  final String? notizen;
  final DateTime? registriertAm;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined
  final String? planId;
  final String? planBezeichnung;

  AdminKundenprofil({
    required this.id,
    this.userId,
    required this.firmaName,
    this.kontaktperson,
    this.email,
    this.telefon,
    this.strasse,
    this.hausnummer,
    this.plz,
    this.ort,
    this.status = 'aktiv',
    this.mwstMethode = 'effektiv',
    this.anzahlMitarbeiter = 1,
    this.anzahlFahrzeuge = 0,
    this.branche,
    this.notizen,
    this.registriertAm,
    this.createdAt,
    this.updatedAt,
    this.planId,
    this.planBezeichnung,
  });

  factory AdminKundenprofil.fromJson(Map<String, dynamic> json) {
    String? planId;
    String? planBez;
    if (json['user_subscriptions'] is Map) {
      final sub = json['user_subscriptions'] as Map;
      planId = sub['plan_id'] as String?;
      if (sub['subscription_plans'] is Map) {
        planBez = (sub['subscription_plans'] as Map)['bezeichnung'] as String?;
      }
    }
    return AdminKundenprofil(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      firmaName: json['firma_name'] as String? ?? '',
      kontaktperson: json['kontaktperson'] as String?,
      email: json['email'] as String?,
      telefon: json['telefon'] as String?,
      strasse: json['strasse'] as String?,
      hausnummer: json['hausnummer'] as String?,
      plz: json['plz'] as String?,
      ort: json['ort'] as String?,
      status: json['status'] as String? ?? 'aktiv',
      mwstMethode: json['mwst_methode'] as String? ?? 'effektiv',
      anzahlMitarbeiter: json['anzahl_mitarbeiter'] as int? ?? 1,
      anzahlFahrzeuge: json['anzahl_fahrzeuge'] as int? ?? 0,
      branche: json['branche'] as String?,
      notizen: json['notizen'] as String?,
      registriertAm: json['registriert_am'] != null
          ? DateTime.parse(json['registriert_am'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      planId: planId,
      planBezeichnung: planBez,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'firma_name': firmaName,
      'kontaktperson': kontaktperson,
      'email': email,
      'telefon': telefon,
      'strasse': strasse,
      'hausnummer': hausnummer,
      'plz': plz,
      'ort': ort,
      'status': status,
      'mwst_methode': mwstMethode,
      'anzahl_mitarbeiter': anzahlMitarbeiter,
      'anzahl_fahrzeuge': anzahlFahrzeuge,
      'branche': branche,
      'notizen': notizen,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'aktiv':
        return 'Aktiv';
      case 'inaktiv':
        return 'Inaktiv';
      case 'gesperrt':
        return 'Gesperrt';
      case 'test':
        return 'Test';
      default:
        return status;
    }
  }

  String get mwstMethodeLabel {
    switch (mwstMethode) {
      case 'effektiv':
        return 'Effektive Methode';
      case 'saldosteuersatz':
        return 'Saldosteuersatz';
      default:
        return mwstMethode;
    }
  }

  String get strasseMitNr {
    final s = strasse ?? '';
    final h = hausnummer ?? '';
    return '$s $h'.trim();
  }

  String get adresseEinzeilig {
    final parts = <String>[];
    final sm = strasseMitNr;
    if (sm.isNotEmpty) parts.add(sm);
    if (plz != null && ort != null) {
      parts.add('$plz $ort');
    } else if (ort != null && ort!.isNotEmpty) {
      parts.add(ort!);
    }
    return parts.join(', ');
  }
}
