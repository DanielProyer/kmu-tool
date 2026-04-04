/// Ergebnis eines Beleg-Scans (OCR via Claude Haiku).
class BelegScanResult {
  final String geschaeft;
  final DateTime datum;
  final List<BelegPosition> positionen;
  final double totalBrutto;
  final double konfidenz;
  final String zahlungsmethode; // bar, karte, twint, unbekannt

  BelegScanResult({
    required this.geschaeft,
    required this.datum,
    required this.positionen,
    required this.totalBrutto,
    required this.konfidenz,
    required this.zahlungsmethode,
  });

  factory BelegScanResult.fromJson(Map<String, dynamic> json) {
    return BelegScanResult(
      geschaeft: json['geschaeft'] as String? ?? 'Unbekannt',
      datum: DateTime.tryParse(json['datum'] as String? ?? '') ?? DateTime.now(),
      positionen: (json['positionen'] as List<dynamic>?)
              ?.map((p) => BelegPosition.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      totalBrutto: (json['total_brutto'] as num?)?.toDouble() ?? 0,
      konfidenz: (json['konfidenz'] as num?)?.toDouble() ?? 0,
      zahlungsmethode: json['zahlungsmethode'] as String? ?? 'unbekannt',
    );
  }

  bool get istMischkauf =>
      positionen.length > 1 &&
      positionen.any((p) => p.istBenzin) &&
      positionen.any((p) => !p.istBenzin);
}

/// Eine Position auf einem gescannten Beleg.
class BelegPosition {
  final String beschreibung;
  final String kategorie; // benzin, essen
  final double betragBrutto;
  final double mwstSatz;

  BelegPosition({
    required this.beschreibung,
    required this.kategorie,
    required this.betragBrutto,
    required this.mwstSatz,
  });

  factory BelegPosition.fromJson(Map<String, dynamic> json) {
    return BelegPosition(
      beschreibung: json['beschreibung'] as String? ?? '',
      kategorie: json['kategorie'] as String? ?? 'essen',
      betragBrutto: (json['betrag_brutto'] as num?)?.toDouble() ?? 0,
      mwstSatz: (json['mwst_satz'] as num?)?.toDouble() ?? 8.1,
    );
  }

  bool get istBenzin => kategorie == 'benzin';

  double get betragNetto => betragBrutto / (1 + mwstSatz / 100);

  double get mwstBetrag => betragBrutto - betragNetto;
}
