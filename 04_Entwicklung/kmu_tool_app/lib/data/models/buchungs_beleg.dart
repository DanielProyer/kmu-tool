/// Metadaten eines Buchungs-Belegs (Anhang zu einer Buchung).
class BuchungsBeleg {
  final String id;
  final String userId;
  final String buchungId;
  final String dateiname;
  final String dateityp;
  final String storagePfad;
  final String belegQuelle; // manuell, spesen_scan, rechnung
  final String? beschreibung;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BuchungsBeleg({
    required this.id,
    required this.userId,
    required this.buchungId,
    required this.dateiname,
    required this.dateityp,
    required this.storagePfad,
    required this.belegQuelle,
    this.beschreibung,
    this.createdAt,
    this.updatedAt,
  });

  factory BuchungsBeleg.fromJson(Map<String, dynamic> json) {
    return BuchungsBeleg(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      buchungId: json['buchung_id'] as String,
      dateiname: json['dateiname'] as String,
      dateityp: json['dateityp'] as String,
      storagePfad: json['storage_pfad'] as String,
      belegQuelle: json['beleg_quelle'] as String? ?? 'manuell',
      beschreibung: json['beschreibung'] as String?,
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
      'buchung_id': buchungId,
      'dateiname': dateiname,
      'dateityp': dateityp,
      'storage_pfad': storagePfad,
      'beleg_quelle': belegQuelle,
      'beschreibung': beschreibung,
    };
  }

  String get quelleLabel {
    switch (belegQuelle) {
      case 'spesen_scan':
        return 'Spesen-Scan';
      case 'rechnung':
        return 'Rechnung';
      default:
        return 'Manuell';
    }
  }
}
