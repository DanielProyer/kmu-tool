class Bestellvorschlag {
  final String id;
  final String userId;
  final String artikelId;
  final String? lieferantId;
  final double vorgeschlageneMenge;
  final double aktuellerBestand;
  final double mindestbestand;
  final String status; // offen, bestellt, ignoriert
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields
  final String? artikelBezeichnung;
  final String? artikelArtikelnummer;
  final String? artikelEinheit;
  final String? lieferantFirma;

  Bestellvorschlag({
    required this.id,
    required this.userId,
    required this.artikelId,
    this.lieferantId,
    required this.vorgeschlageneMenge,
    this.aktuellerBestand = 0,
    this.mindestbestand = 0,
    this.status = 'offen',
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.artikelBezeichnung,
    this.artikelArtikelnummer,
    this.artikelEinheit,
    this.lieferantFirma,
  });

  factory Bestellvorschlag.fromJson(Map<String, dynamic> json) {
    String? artikelBez;
    String? artikelNr;
    String? artikelEinheit;
    String? liefFirma;

    if (json['artikel'] is Map) {
      final a = json['artikel'] as Map;
      artikelBez = a['bezeichnung'] as String?;
      artikelNr = a['artikelnummer'] as String?;
      artikelEinheit = a['einheit'] as String?;
    }
    if (json['lieferanten'] is Map) {
      liefFirma = (json['lieferanten'] as Map)['firma'] as String?;
    }

    return Bestellvorschlag(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      artikelId: json['artikel_id'] as String,
      lieferantId: json['lieferant_id'] as String?,
      vorgeschlageneMenge:
          (json['vorgeschlagene_menge'] as num?)?.toDouble() ?? 0,
      aktuellerBestand:
          (json['aktueller_bestand'] as num?)?.toDouble() ?? 0,
      mindestbestand: (json['mindestbestand'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'offen',
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      artikelBezeichnung: artikelBez,
      artikelArtikelnummer: artikelNr,
      artikelEinheit: artikelEinheit,
      lieferantFirma: liefFirma,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artikel_id': artikelId,
      'lieferant_id': lieferantId,
      'vorgeschlagene_menge': vorgeschlageneMenge,
      'aktueller_bestand': aktuellerBestand,
      'mindestbestand': mindestbestand,
      'status': status,
      'is_deleted': isDeleted,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'offen':
        return 'Offen';
      case 'bestellt':
        return 'Bestellt';
      case 'ignoriert':
        return 'Ignoriert';
      default:
        return status;
    }
  }

  double get fehlmenge => mindestbestand - aktuellerBestand;
}
