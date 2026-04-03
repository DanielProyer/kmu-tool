class Bestellung {
  final String id;
  final String userId;
  final String lieferantId;
  final String bestellNr;
  final String status; // entwurf, bestellt, teilgeliefert, geliefert, storniert
  final DateTime? bestellDatum;
  final DateTime? erwartetesLieferdatum;
  final DateTime? lieferDatum;
  final String? bemerkung;
  final double totalBetrag;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields
  final String? lieferantFirma;

  Bestellung({
    required this.id,
    required this.userId,
    required this.lieferantId,
    required this.bestellNr,
    this.status = 'entwurf',
    this.bestellDatum,
    this.erwartetesLieferdatum,
    this.lieferDatum,
    this.bemerkung,
    this.totalBetrag = 0,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.lieferantFirma,
  });

  factory Bestellung.fromJson(Map<String, dynamic> json) {
    String? liefFirma;
    if (json['lieferanten'] is Map) {
      liefFirma = (json['lieferanten'] as Map)['firma'] as String?;
    }

    return Bestellung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      lieferantId: json['lieferant_id'] as String,
      bestellNr: json['bestell_nr'] as String? ?? '',
      status: json['status'] as String? ?? 'entwurf',
      bestellDatum: json['bestell_datum'] != null
          ? DateTime.parse(json['bestell_datum'] as String)
          : null,
      erwartetesLieferdatum: json['erwartetes_lieferdatum'] != null
          ? DateTime.parse(json['erwartetes_lieferdatum'] as String)
          : null,
      lieferDatum: json['liefer_datum'] != null
          ? DateTime.parse(json['liefer_datum'] as String)
          : null,
      bemerkung: json['bemerkung'] as String?,
      totalBetrag: (json['total_betrag'] as num?)?.toDouble() ?? 0,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lieferantFirma: liefFirma,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'lieferant_id': lieferantId,
      'bestell_nr': bestellNr,
      'status': status,
      'bestell_datum': bestellDatum?.toIso8601String().split('T').first,
      'erwartetes_lieferdatum':
          erwartetesLieferdatum?.toIso8601String().split('T').first,
      'liefer_datum': lieferDatum?.toIso8601String().split('T').first,
      'bemerkung': bemerkung,
      'total_betrag': totalBetrag,
      'is_deleted': isDeleted,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'entwurf':
        return 'Entwurf';
      case 'bestellt':
        return 'Bestellt';
      case 'teilgeliefert':
        return 'Teilgeliefert';
      case 'geliefert':
        return 'Geliefert';
      case 'storniert':
        return 'Storniert';
      default:
        return status;
    }
  }

  bool get isOffen => status == 'entwurf' || status == 'bestellt' || status == 'teilgeliefert';
}
