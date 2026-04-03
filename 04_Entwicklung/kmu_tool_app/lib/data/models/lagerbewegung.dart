class Lagerbewegung {
  final String id;
  final String userId;
  final String artikelId;
  final String lagerortId;
  final String? zielLagerortId;
  final String bewegungstyp; // eingang, ausgang, umlagerung, korrektur, inventur
  final double menge;
  final String? referenzTyp;
  final String? referenzId;
  final String? bemerkung;
  final DateTime? createdAt;

  // Joined fields
  final String? lagerortBezeichnung;
  final String? zielLagerortBezeichnung;

  Lagerbewegung({
    required this.id,
    required this.userId,
    required this.artikelId,
    required this.lagerortId,
    this.zielLagerortId,
    required this.bewegungstyp,
    required this.menge,
    this.referenzTyp,
    this.referenzId,
    this.bemerkung,
    this.createdAt,
    this.lagerortBezeichnung,
    this.zielLagerortBezeichnung,
  });

  factory Lagerbewegung.fromJson(Map<String, dynamic> json) {
    String? quellBezeichnung;
    String? zielBezeichnung;
    if (json['lagerorte'] is Map) {
      quellBezeichnung =
          (json['lagerorte'] as Map)['bezeichnung'] as String?;
    }
    if (json['ziel_lagerorte'] is Map) {
      zielBezeichnung =
          (json['ziel_lagerorte'] as Map)['bezeichnung'] as String?;
    }
    return Lagerbewegung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      artikelId: json['artikel_id'] as String,
      lagerortId: json['lagerort_id'] as String,
      zielLagerortId: json['ziel_lagerort_id'] as String?,
      bewegungstyp: json['bewegungstyp'] as String,
      menge: (json['menge'] as num?)?.toDouble() ?? 0,
      referenzTyp: json['referenz_typ'] as String?,
      referenzId: json['referenz_id'] as String?,
      bemerkung: json['bemerkung'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      lagerortBezeichnung: quellBezeichnung,
      zielLagerortBezeichnung: zielBezeichnung,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artikel_id': artikelId,
      'lagerort_id': lagerortId,
      'ziel_lagerort_id': zielLagerortId,
      'bewegungstyp': bewegungstyp,
      'menge': menge,
      'referenz_typ': referenzTyp,
      'referenz_id': referenzId,
      'bemerkung': bemerkung,
    };
  }

  String get bewegungstypLabel {
    switch (bewegungstyp) {
      case 'eingang':
        return 'Wareneingang';
      case 'ausgang':
        return 'Warenausgang';
      case 'umlagerung':
        return 'Umlagerung';
      case 'korrektur':
        return 'Korrektur';
      case 'inventur':
        return 'Inventur';
      default:
        return bewegungstyp;
    }
  }
}
