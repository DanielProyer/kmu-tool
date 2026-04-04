class Sozialversicherung {
  final String id;
  final String userId;

  // AHV/IV/EO
  final double ahvSatzAg;
  final double ahvSatzAn;

  // ALV
  final double alvSatzAg;
  final double alvSatzAn;
  final double alvGrenze;
  final double alv2Satz;

  // UVG
  final double uvgBuSatz;
  final double uvgNbuSatz;
  final double uvgMaxVerdienst;

  // KTG
  final double ktgSatzAg;
  final double ktgSatzAn;

  // BVG
  final String? bvgAnbieter;
  final String? bvgVertragNr;
  final double bvgKoordinationsabzug;
  final double bvgEintrittsschwelle;
  final double bvgMaxVersicherterLohn;
  final double bvgSatz2534;
  final double bvgSatz3544;
  final double bvgSatz4554;
  final double bvgSatz5564;
  final double bvgAgAnteilProzent;

  // Kinderzulagen (FAK)
  final double kinderzulageBetrag;
  final double ausbildungszulageBetrag;

  // Quellensteuer
  final bool quellensteuerAktiv;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sozialversicherung({
    required this.id,
    required this.userId,
    this.ahvSatzAg = 5.3,
    this.ahvSatzAn = 5.3,
    this.alvSatzAg = 1.1,
    this.alvSatzAn = 1.1,
    this.alvGrenze = 148200.0,
    this.alv2Satz = 1.0,
    this.uvgBuSatz = 0.0,
    this.uvgNbuSatz = 0.0,
    this.uvgMaxVerdienst = 148200.0,
    this.ktgSatzAg = 0.0,
    this.ktgSatzAn = 0.0,
    this.bvgAnbieter,
    this.bvgVertragNr,
    this.bvgKoordinationsabzug = 25725.0,
    this.bvgEintrittsschwelle = 22050.0,
    this.bvgMaxVersicherterLohn = 88200.0,
    this.bvgSatz2534 = 7.0,
    this.bvgSatz3544 = 10.0,
    this.bvgSatz4554 = 15.0,
    this.bvgSatz5564 = 18.0,
    this.bvgAgAnteilProzent = 50.0,
    this.kinderzulageBetrag = 200.0,
    this.ausbildungszulageBetrag = 250.0,
    this.quellensteuerAktiv = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Sozialversicherung.fromJson(Map<String, dynamic> json) {
    return Sozialversicherung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      ahvSatzAg: (json['ahv_satz_ag'] as num?)?.toDouble() ?? 5.3,
      ahvSatzAn: (json['ahv_satz_an'] as num?)?.toDouble() ?? 5.3,
      alvSatzAg: (json['alv_satz_ag'] as num?)?.toDouble() ?? 1.1,
      alvSatzAn: (json['alv_satz_an'] as num?)?.toDouble() ?? 1.1,
      alvGrenze: (json['alv_grenze'] as num?)?.toDouble() ?? 148200.0,
      alv2Satz: (json['alv2_satz'] as num?)?.toDouble() ?? 1.0,
      uvgBuSatz: (json['uvg_bu_satz'] as num?)?.toDouble() ?? 0.0,
      uvgNbuSatz: (json['uvg_nbu_satz'] as num?)?.toDouble() ?? 0.0,
      uvgMaxVerdienst: (json['uvg_max_verdienst'] as num?)?.toDouble() ?? 148200.0,
      ktgSatzAg: (json['ktg_satz_ag'] as num?)?.toDouble() ?? 0.0,
      ktgSatzAn: (json['ktg_satz_an'] as num?)?.toDouble() ?? 0.0,
      bvgAnbieter: json['bvg_anbieter'] as String?,
      bvgVertragNr: json['bvg_vertrag_nr'] as String?,
      bvgKoordinationsabzug: (json['bvg_koordinationsabzug'] as num?)?.toDouble() ?? 25725.0,
      bvgEintrittsschwelle: (json['bvg_eintrittsschwelle'] as num?)?.toDouble() ?? 22050.0,
      bvgMaxVersicherterLohn: (json['bvg_max_versicherter_lohn'] as num?)?.toDouble() ?? 88200.0,
      bvgSatz2534: (json['bvg_satz_25_34'] as num?)?.toDouble() ?? 7.0,
      bvgSatz3544: (json['bvg_satz_35_44'] as num?)?.toDouble() ?? 10.0,
      bvgSatz4554: (json['bvg_satz_45_54'] as num?)?.toDouble() ?? 15.0,
      bvgSatz5564: (json['bvg_satz_55_64'] as num?)?.toDouble() ?? 18.0,
      bvgAgAnteilProzent: (json['bvg_ag_anteil_prozent'] as num?)?.toDouble() ?? 50.0,
      kinderzulageBetrag: (json['kinderzulage_betrag'] as num?)?.toDouble() ?? 200.0,
      ausbildungszulageBetrag: (json['ausbildungszulage_betrag'] as num?)?.toDouble() ?? 250.0,
      quellensteuerAktiv: json['quellensteuer_aktiv'] as bool? ?? false,
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
      'ahv_satz_ag': ahvSatzAg,
      'ahv_satz_an': ahvSatzAn,
      'alv_satz_ag': alvSatzAg,
      'alv_satz_an': alvSatzAn,
      'alv_grenze': alvGrenze,
      'alv2_satz': alv2Satz,
      'uvg_bu_satz': uvgBuSatz,
      'uvg_nbu_satz': uvgNbuSatz,
      'uvg_max_verdienst': uvgMaxVerdienst,
      'ktg_satz_ag': ktgSatzAg,
      'ktg_satz_an': ktgSatzAn,
      'bvg_anbieter': bvgAnbieter,
      'bvg_vertrag_nr': bvgVertragNr,
      'bvg_koordinationsabzug': bvgKoordinationsabzug,
      'bvg_eintrittsschwelle': bvgEintrittsschwelle,
      'bvg_max_versicherter_lohn': bvgMaxVersicherterLohn,
      'bvg_satz_25_34': bvgSatz2534,
      'bvg_satz_35_44': bvgSatz3544,
      'bvg_satz_45_54': bvgSatz4554,
      'bvg_satz_55_64': bvgSatz5564,
      'bvg_ag_anteil_prozent': bvgAgAnteilProzent,
      'kinderzulage_betrag': kinderzulageBetrag,
      'ausbildungszulage_betrag': ausbildungszulageBetrag,
      'quellensteuer_aktiv': quellensteuerAktiv,
    };
  }

  /// BVG-Satz basierend auf Alter.
  double bvgSatzFuerAlter(int alter) {
    if (alter < 25) return 0.0;
    if (alter <= 34) return bvgSatz2534;
    if (alter <= 44) return bvgSatz3544;
    if (alter <= 54) return bvgSatz4554;
    if (alter <= 64) return bvgSatz5564;
    return 0.0;
  }
}
