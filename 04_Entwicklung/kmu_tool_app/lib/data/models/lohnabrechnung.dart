class Lohnabrechnung {
  final String id;
  final String userId;
  final String mitarbeiterId;
  final int monat;
  final int jahr;

  // Brutto
  final double bruttolohn;
  final double pensum;

  // AN-Abzuege
  final double ahvAn;
  final double alvAn;
  final double uvgNbuAn;
  final double ktgAn;
  final double bvgAn;
  final double quellensteuer;

  // Zulagen
  final double kinderzulagen;

  // Netto
  final double nettolohn;

  // AG-Kosten
  final double ahvAg;
  final double alvAg;
  final double uvgBuAg;
  final double ktgAg;
  final double bvgAg;
  final double fakAg;
  final double totalAgKosten;

  // Status
  final String status; // entwurf, freigegeben, ausbezahlt

  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lohnabrechnung({
    required this.id,
    required this.userId,
    required this.mitarbeiterId,
    required this.monat,
    required this.jahr,
    this.bruttolohn = 0,
    this.pensum = 1.0,
    this.ahvAn = 0,
    this.alvAn = 0,
    this.uvgNbuAn = 0,
    this.ktgAn = 0,
    this.bvgAn = 0,
    this.quellensteuer = 0,
    this.kinderzulagen = 0,
    this.nettolohn = 0,
    this.ahvAg = 0,
    this.alvAg = 0,
    this.uvgBuAg = 0,
    this.ktgAg = 0,
    this.bvgAg = 0,
    this.fakAg = 0,
    this.totalAgKosten = 0,
    this.status = 'entwurf',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Lohnabrechnung.fromJson(Map<String, dynamic> json) {
    return Lohnabrechnung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mitarbeiterId: json['mitarbeiter_id'] as String,
      monat: json['monat'] as int,
      jahr: json['jahr'] as int,
      bruttolohn: (json['bruttolohn'] as num?)?.toDouble() ?? 0,
      pensum: (json['pensum'] as num?)?.toDouble() ?? 1.0,
      ahvAn: (json['ahv_an'] as num?)?.toDouble() ?? 0,
      alvAn: (json['alv_an'] as num?)?.toDouble() ?? 0,
      uvgNbuAn: (json['uvg_nbu_an'] as num?)?.toDouble() ?? 0,
      ktgAn: (json['ktg_an'] as num?)?.toDouble() ?? 0,
      bvgAn: (json['bvg_an'] as num?)?.toDouble() ?? 0,
      quellensteuer: (json['quellensteuer'] as num?)?.toDouble() ?? 0,
      kinderzulagen: (json['kinderzulagen'] as num?)?.toDouble() ?? 0,
      nettolohn: (json['nettolohn'] as num?)?.toDouble() ?? 0,
      ahvAg: (json['ahv_ag'] as num?)?.toDouble() ?? 0,
      alvAg: (json['alv_ag'] as num?)?.toDouble() ?? 0,
      uvgBuAg: (json['uvg_bu_ag'] as num?)?.toDouble() ?? 0,
      ktgAg: (json['ktg_ag'] as num?)?.toDouble() ?? 0,
      bvgAg: (json['bvg_ag'] as num?)?.toDouble() ?? 0,
      fakAg: (json['fak_ag'] as num?)?.toDouble() ?? 0,
      totalAgKosten: (json['total_ag_kosten'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'entwurf',
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
      'mitarbeiter_id': mitarbeiterId,
      'monat': monat,
      'jahr': jahr,
      'bruttolohn': bruttolohn,
      'pensum': pensum,
      'ahv_an': ahvAn,
      'alv_an': alvAn,
      'uvg_nbu_an': uvgNbuAn,
      'ktg_an': ktgAn,
      'bvg_an': bvgAn,
      'quellensteuer': quellensteuer,
      'kinderzulagen': kinderzulagen,
      'nettolohn': nettolohn,
      'ahv_ag': ahvAg,
      'alv_ag': alvAg,
      'uvg_bu_ag': uvgBuAg,
      'ktg_ag': ktgAg,
      'bvg_ag': bvgAg,
      'fak_ag': fakAg,
      'total_ag_kosten': totalAgKosten,
      'status': status,
      'is_deleted': isDeleted,
    };
  }

  double get totalAnAbzuege =>
      ahvAn + alvAn + uvgNbuAn + ktgAn + bvgAn + quellensteuer;

  String get statusLabel {
    switch (status) {
      case 'entwurf': return 'Entwurf';
      case 'freigegeben': return 'Freigegeben';
      case 'ausbezahlt': return 'Ausbezahlt';
      default: return status;
    }
  }

  String get periodeLabel {
    const monate = [
      'Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
    ];
    return '${monate[monat - 1]} $jahr';
  }
}
