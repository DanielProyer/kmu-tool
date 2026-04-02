class MwstAbrechnung {
  final String id;
  final String userId;

  // Periode
  final DateTime periodeStart;
  final DateTime periodeEnd;
  final String methode;

  // Teil I: Umsatz
  final double ziff200; // Total Entgelte
  final double ziff220; // Steuerbefreit
  final double ziff225; // Ausgenommen
  final double ziff235; // Entgeltsminderungen
  final double ziff280; // Diverses
  final double ziff289; // Total Abzuege
  final double ziff299; // Steuerbarer Umsatz

  // Teil II: Steuerberechnung (Effektiv)
  final double ziff302Umsatz;
  final double ziff302Steuer;
  final double ziff312Umsatz;
  final double ziff312Steuer;
  final double ziff342Umsatz;
  final double ziff342Steuer;

  // Teil II: Steuerberechnung (SSS)
  final double ziff322Umsatz;
  final double ziff322Steuer;
  final double ziff332Umsatz;
  final double ziff332Steuer;

  // Bezugsteuer + Total
  final double ziff382;
  final double ziff399; // Total geschuldete Steuer

  // Teil III: Vorsteuer
  final double ziff400; // Vorsteuer Material/DL
  final double ziff405; // Vorsteuer Investitionen
  final double ziff479; // Total Vorsteuer

  // Teil IV: Zahllast
  final double ziff500; // An ESTV zu zahlen
  final double ziff510; // Guthaben

  // Status
  final String status;
  final DateTime? eingereichtAm;
  final DateTime? bezahltAm;
  final String? notizen;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  MwstAbrechnung({
    required this.id,
    required this.userId,
    required this.periodeStart,
    required this.periodeEnd,
    required this.methode,
    this.ziff200 = 0,
    this.ziff220 = 0,
    this.ziff225 = 0,
    this.ziff235 = 0,
    this.ziff280 = 0,
    this.ziff289 = 0,
    this.ziff299 = 0,
    this.ziff302Umsatz = 0,
    this.ziff302Steuer = 0,
    this.ziff312Umsatz = 0,
    this.ziff312Steuer = 0,
    this.ziff342Umsatz = 0,
    this.ziff342Steuer = 0,
    this.ziff322Umsatz = 0,
    this.ziff322Steuer = 0,
    this.ziff332Umsatz = 0,
    this.ziff332Steuer = 0,
    this.ziff382 = 0,
    this.ziff399 = 0,
    this.ziff400 = 0,
    this.ziff405 = 0,
    this.ziff479 = 0,
    this.ziff500 = 0,
    this.ziff510 = 0,
    this.status = 'entwurf',
    this.eingereichtAm,
    this.bezahltAm,
    this.notizen,
    this.createdAt,
    this.updatedAt,
  });

  factory MwstAbrechnung.fromJson(Map<String, dynamic> json) {
    return MwstAbrechnung(
      id: json['id'],
      userId: json['user_id'],
      periodeStart: DateTime.parse(json['periode_start']),
      periodeEnd: DateTime.parse(json['periode_end']),
      methode: json['methode'],
      ziff200: (json['ziff_200'] as num?)?.toDouble() ?? 0,
      ziff220: (json['ziff_220'] as num?)?.toDouble() ?? 0,
      ziff225: (json['ziff_225'] as num?)?.toDouble() ?? 0,
      ziff235: (json['ziff_235'] as num?)?.toDouble() ?? 0,
      ziff280: (json['ziff_280'] as num?)?.toDouble() ?? 0,
      ziff289: (json['ziff_289'] as num?)?.toDouble() ?? 0,
      ziff299: (json['ziff_299'] as num?)?.toDouble() ?? 0,
      ziff302Umsatz: (json['ziff_302_umsatz'] as num?)?.toDouble() ?? 0,
      ziff302Steuer: (json['ziff_302_steuer'] as num?)?.toDouble() ?? 0,
      ziff312Umsatz: (json['ziff_312_umsatz'] as num?)?.toDouble() ?? 0,
      ziff312Steuer: (json['ziff_312_steuer'] as num?)?.toDouble() ?? 0,
      ziff342Umsatz: (json['ziff_342_umsatz'] as num?)?.toDouble() ?? 0,
      ziff342Steuer: (json['ziff_342_steuer'] as num?)?.toDouble() ?? 0,
      ziff322Umsatz: (json['ziff_322_umsatz'] as num?)?.toDouble() ?? 0,
      ziff322Steuer: (json['ziff_322_steuer'] as num?)?.toDouble() ?? 0,
      ziff332Umsatz: (json['ziff_332_umsatz'] as num?)?.toDouble() ?? 0,
      ziff332Steuer: (json['ziff_332_steuer'] as num?)?.toDouble() ?? 0,
      ziff382: (json['ziff_382'] as num?)?.toDouble() ?? 0,
      ziff399: (json['ziff_399'] as num?)?.toDouble() ?? 0,
      ziff400: (json['ziff_400'] as num?)?.toDouble() ?? 0,
      ziff405: (json['ziff_405'] as num?)?.toDouble() ?? 0,
      ziff479: (json['ziff_479'] as num?)?.toDouble() ?? 0,
      ziff500: (json['ziff_500'] as num?)?.toDouble() ?? 0,
      ziff510: (json['ziff_510'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'entwurf',
      eingereichtAm: json['eingereicht_am'] != null
          ? DateTime.parse(json['eingereicht_am'])
          : null,
      bezahltAm: json['bezahlt_am'] != null
          ? DateTime.parse(json['bezahlt_am'])
          : null,
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
      'user_id': userId,
      'periode_start': periodeStart.toIso8601String().split('T').first,
      'periode_end': periodeEnd.toIso8601String().split('T').first,
      'methode': methode,
      'ziff_200': ziff200,
      'ziff_220': ziff220,
      'ziff_225': ziff225,
      'ziff_235': ziff235,
      'ziff_280': ziff280,
      'ziff_289': ziff289,
      'ziff_299': ziff299,
      'ziff_302_umsatz': ziff302Umsatz,
      'ziff_302_steuer': ziff302Steuer,
      'ziff_312_umsatz': ziff312Umsatz,
      'ziff_312_steuer': ziff312Steuer,
      'ziff_342_umsatz': ziff342Umsatz,
      'ziff_342_steuer': ziff342Steuer,
      'ziff_322_umsatz': ziff322Umsatz,
      'ziff_322_steuer': ziff322Steuer,
      'ziff_332_umsatz': ziff332Umsatz,
      'ziff_332_steuer': ziff332Steuer,
      'ziff_382': ziff382,
      'ziff_399': ziff399,
      'ziff_400': ziff400,
      'ziff_405': ziff405,
      'ziff_479': ziff479,
      'ziff_500': ziff500,
      'ziff_510': ziff510,
      'status': status,
      'eingereicht_am': eingereichtAm?.toIso8601String(),
      'bezahlt_am': bezahltAm?.toIso8601String(),
      'notizen': notizen,
    };
  }

  bool get isEffektiv => methode == 'effektiv';
  bool get isSaldosteuersatz => methode == 'saldosteuersatz';
  bool get istZahllast => ziff500 > 0;
  bool get istGuthaben => ziff510 > 0;

  String get statusLabel {
    switch (status) {
      case 'entwurf':
        return 'Entwurf';
      case 'eingereicht':
        return 'Eingereicht';
      case 'bezahlt':
        return 'Bezahlt';
      default:
        return status;
    }
  }

  String get periodeLabel {
    final startMonth = periodeStart.month;
    final endMonth = periodeEnd.month;
    final year = periodeStart.year;

    if (startMonth == 1 && endMonth == 12) return 'Jahr $year';
    if (endMonth - startMonth == 5) {
      return startMonth == 1 ? '1. Halbjahr $year' : '2. Halbjahr $year';
    }
    final q = ((startMonth - 1) ~/ 3) + 1;
    return 'Q$q $year';
  }
}
