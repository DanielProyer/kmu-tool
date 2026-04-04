import 'dart:math';
import 'package:uuid/uuid.dart';
import '../../data/models/lohnabrechnung.dart';
import '../../data/models/mitarbeiter.dart';
import '../../data/models/sozialversicherung.dart';

/// Zentrale Berechnungslogik fuer Schweizer Lohnabrechnungen.
class LohnService {
  /// Berechnet eine vollstaendige Lohnabrechnung.
  static Lohnabrechnung berechne({
    required Mitarbeiter mitarbeiter,
    required Sozialversicherung sv,
    required String userId,
    required int monat,
    required int jahr,
    String? existingId,
    String existingStatus = 'entwurf',
  }) {
    final brutto = (mitarbeiter.bruttolohnMonat ?? 0) * mitarbeiter.pensum;
    final jahresLohn = brutto * 12;

    // --- AN-Abzuege ---

    // AHV/IV/EO
    final ahvAn = _round(brutto * sv.ahvSatzAn / 100);

    // ALV: gedeckelt auf Monatsgrenze
    final alvMonatsgrenze = sv.alvGrenze / 12;
    final alvBasis = min(brutto, alvMonatsgrenze);
    double alvAn = _round(alvBasis * sv.alvSatzAn / 100);
    // ALV2 Solidaritaetsbeitrag fuer Lohn ueber Grenze
    if (brutto > alvMonatsgrenze) {
      alvAn += _round((brutto - alvMonatsgrenze) * sv.alv2Satz / 100);
    }

    // UVG-NBU (AN-Anteil), gedeckelt
    final uvgMonatsgrenze = sv.uvgMaxVerdienst / 12;
    final uvgBasis = min(brutto, uvgMonatsgrenze);
    final uvgNbuAn = _round(uvgBasis * sv.uvgNbuSatz / 100);

    // KTG (AN-Anteil)
    final ktgAn = _round(brutto * sv.ktgSatzAn / 100);

    // BVG
    double bvgAn = 0;
    double bvgAg = 0;
    final alter = mitarbeiter.alter;
    if (alter != null && alter >= 25 && jahresLohn > sv.bvgEintrittsschwelle) {
      final versicherterLohn = min(jahresLohn, sv.bvgMaxVersicherterLohn) -
          sv.bvgKoordinationsabzug;
      if (versicherterLohn > 0) {
        final bvgSatz = sv.bvgSatzFuerAlter(alter);
        final bvgTotal = versicherterLohn * bvgSatz / 100;
        final bvgMonatlich = bvgTotal / 12;
        // AN-Anteil: (100 - AG-Anteil)%
        final anAnteil = (100 - sv.bvgAgAnteilProzent) / 100;
        bvgAn = _round(bvgMonatlich * anAnteil);
        bvgAg = _round(bvgMonatlich * sv.bvgAgAnteilProzent / 100);
      }
    }

    // Quellensteuer
    double quellensteuer = 0;
    if (sv.quellensteuerAktiv &&
        mitarbeiter.quellensteuerSatz != null &&
        mitarbeiter.quellensteuerSatz! > 0) {
      quellensteuer = _round(brutto * mitarbeiter.quellensteuerSatz! / 100);
    }

    // Kinderzulagen
    final kinderzulagen = _round(
      mitarbeiter.anzahlKinder * sv.kinderzulageBetrag +
          mitarbeiter.anzahlKinderAusbildung * sv.ausbildungszulageBetrag,
    );

    // Netto
    final totalAnAbzuege = ahvAn + alvAn + uvgNbuAn + ktgAn + bvgAn + quellensteuer;
    final netto = _round(brutto - totalAnAbzuege + kinderzulagen);

    // --- AG-Kosten ---
    final ahvAg = _round(brutto * sv.ahvSatzAg / 100);

    double alvAg = _round(alvBasis * sv.alvSatzAg / 100);
    if (brutto > alvMonatsgrenze) {
      alvAg += _round((brutto - alvMonatsgrenze) * sv.alv2Satz / 100);
    }

    final uvgBuAg = _round(uvgBasis * sv.uvgBuSatz / 100);
    final ktgAg = _round(brutto * sv.ktgSatzAg / 100);

    // FAK (Familienzulagen-Beitrag AG) = Kinderzulagen
    final fakAg = kinderzulagen;

    final totalAgKosten =
        _round(ahvAg + alvAg + uvgBuAg + ktgAg + bvgAg + fakAg);

    return Lohnabrechnung(
      id: existingId ?? const Uuid().v4(),
      userId: userId,
      mitarbeiterId: mitarbeiter.id,
      monat: monat,
      jahr: jahr,
      bruttolohn: _round(brutto),
      pensum: mitarbeiter.pensum,
      ahvAn: ahvAn,
      alvAn: alvAn,
      uvgNbuAn: uvgNbuAn,
      ktgAn: ktgAn,
      bvgAn: bvgAn,
      quellensteuer: quellensteuer,
      kinderzulagen: kinderzulagen,
      nettolohn: netto,
      ahvAg: ahvAg,
      alvAg: alvAg,
      uvgBuAg: uvgBuAg,
      ktgAg: ktgAg,
      bvgAg: bvgAg,
      fakAg: fakAg,
      totalAgKosten: totalAgKosten,
      status: existingStatus,
    );
  }

  /// Rundet auf 5 Rappen (Schweizer Standard).
  static double _round(double value) {
    return (value * 20).roundToDouble() / 20;
  }
}
