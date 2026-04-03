class ArtikelLieferant {
  final String id;
  final String userId;
  final String artikelId;
  final String lieferantId;
  final double? einkaufspreis;
  final String? lieferantenArtikelNr;
  final double mindestbestellmenge;
  final int? lieferzeitTage;
  final bool istHauptlieferant;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields
  final String? lieferantFirma;

  ArtikelLieferant({
    required this.id,
    required this.userId,
    required this.artikelId,
    required this.lieferantId,
    this.einkaufspreis,
    this.lieferantenArtikelNr,
    this.mindestbestellmenge = 1,
    this.lieferzeitTage,
    this.istHauptlieferant = false,
    this.createdAt,
    this.updatedAt,
    this.lieferantFirma,
  });

  factory ArtikelLieferant.fromJson(Map<String, dynamic> json) {
    String? firma;
    if (json['lieferanten'] is Map) {
      firma = (json['lieferanten'] as Map)['firma'] as String?;
    }
    return ArtikelLieferant(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      artikelId: json['artikel_id'] as String,
      lieferantId: json['lieferant_id'] as String,
      einkaufspreis: (json['einkaufspreis'] as num?)?.toDouble(),
      lieferantenArtikelNr: json['lieferanten_artikel_nr'] as String?,
      mindestbestellmenge:
          (json['mindestbestellmenge'] as num?)?.toDouble() ?? 1,
      lieferzeitTage: json['lieferzeit_tage'] as int?,
      istHauptlieferant: json['ist_hauptlieferant'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lieferantFirma: firma,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artikel_id': artikelId,
      'lieferant_id': lieferantId,
      'einkaufspreis': einkaufspreis,
      'lieferanten_artikel_nr': lieferantenArtikelNr,
      'mindestbestellmenge': mindestbestellmenge,
      'lieferzeit_tage': lieferzeitTage,
      'ist_hauptlieferant': istHauptlieferant,
    };
  }
}
