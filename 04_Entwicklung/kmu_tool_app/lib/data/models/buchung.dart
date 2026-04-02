class Buchung {
  final String id;
  final String userId;
  final DateTime datum;
  final int sollKonto;
  final int habenKonto;
  final double betrag;
  final String beschreibung;
  final String? belegNr;
  final String? rechnungId;
  final String? mwstCode;
  final double? mwstSatz;
  final double? mwstBetrag;
  final int? monat; // generated
  final int? quartal; // generated
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Buchung({
    required this.id,
    required this.userId,
    required this.datum,
    required this.sollKonto,
    required this.habenKonto,
    required this.betrag,
    required this.beschreibung,
    this.belegNr,
    this.rechnungId,
    this.mwstCode,
    this.mwstSatz,
    this.mwstBetrag,
    this.monat,
    this.quartal,
    this.createdAt,
    this.updatedAt,
  });

  factory Buchung.fromJson(Map<String, dynamic> json) {
    return Buchung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      datum: DateTime.parse(json['datum'] as String),
      sollKonto: json['soll_konto'] as int,
      habenKonto: json['haben_konto'] as int,
      betrag: (json['betrag'] as num?)?.toDouble() ?? 0,
      beschreibung: json['beschreibung'] as String,
      belegNr: json['beleg_nr'] as String?,
      rechnungId: json['rechnung_id'] as String?,
      mwstCode: json['mwst_code'] as String?,
      mwstSatz: (json['mwst_satz'] as num?)?.toDouble(),
      mwstBetrag: (json['mwst_betrag'] as num?)?.toDouble(),
      monat: json['monat'] as int?,
      quartal: json['quartal'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// toJson does NOT include monat/quartal - they are GENERATED in the database.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'datum': datum.toIso8601String(),
      'soll_konto': sollKonto,
      'haben_konto': habenKonto,
      'betrag': betrag,
      'beschreibung': beschreibung,
      'beleg_nr': belegNr,
      'rechnung_id': rechnungId,
      // Migration 014 Spalten - erst senden wenn Migration ausgefuehrt:
      // 'mwst_code': mwstCode,
      // 'mwst_satz': mwstSatz,
      // 'mwst_betrag': mwstBetrag,
    };
  }
}
