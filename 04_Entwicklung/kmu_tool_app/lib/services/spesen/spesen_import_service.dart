import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../../data/models/beleg_scan_result.dart';
import '../../data/models/buchung.dart';
import '../../data/repositories/buchung_repository.dart';
import '../../data/repositories/buchungs_beleg_repository.dart';
import '../auth/betrieb_service.dart';

/// Erstellt Buchungen aus einem Beleg-Scan-Ergebnis.
/// Konten-Mapping (Schweizer KMU Kontenrahmen):
/// - 5800 = Spesen und Entschädigungen (Essen)
/// - 6200 = Fahrzeugaufwand (Benzin)
/// - 1170 = Vorsteuer
/// - 1000 = Kasse (bar)
/// - 1020 = Bank/Post (karte)
/// - 2030 = Kreditkarte
class SpesenImportService {
  static const _uuid = Uuid();
  static final _buchungRepo = BuchungRepository();
  static final _belegRepo = BuchungsBelegRepository();

  /// Erstellt Buchungen für jede Position + Vorsteuer-Buchung.
  /// Gibt die Liste der erstellten Buchungs-IDs zurück.
  static Future<List<String>> importBeleg({
    required BelegScanResult scanResult,
    required String zahlungsmethode, // bar, karte, kreditkarte
    Uint8List? belegBild,
    String? belegDateiname,
    String? belegDateityp,
  }) async {
    final userId = await BetriebService.getDataOwnerId();
    final habenKonto = _zahlungsKonto(zahlungsmethode);
    final buchungIds = <String>[];

    for (final pos in scanResult.positionen) {
      final aufwandKonto = pos.istBenzin ? 6200 : 5800;
      final mwst = _runde5Rappen(pos.mwstBetrag);

      // 1. Aufwand-Buchung: Soll Aufwand / Haben Zahlungsmittel
      final aufwandId = _uuid.v4();
      final belegNr = 'SP-${scanResult.datum.year}${scanResult.datum.month.toString().padLeft(2, '0')}${scanResult.datum.day.toString().padLeft(2, '0')}-${aufwandId.substring(0, 4).toUpperCase()}';

      await _buchungRepo.save(Buchung(
        id: aufwandId,
        userId: userId,
        datum: scanResult.datum,
        sollKonto: aufwandKonto,
        habenKonto: habenKonto,
        betrag: _runde5Rappen(pos.betragBrutto),
        beschreibung:
            '${scanResult.geschaeft} - ${pos.beschreibung}',
        belegNr: belegNr,
        mwstCode: pos.mwstSatz == 2.6 ? 'VM26' : 'VM81',
        mwstSatz: pos.mwstSatz,
        mwstBetrag: mwst,
      ));
      buchungIds.add(aufwandId);

      // 2. Vorsteuer-Buchung: Soll 1170 / Haben Zahlungsmittel
      if (mwst > 0) {
        final vorsteuerId = _uuid.v4();
        await _buchungRepo.save(Buchung(
          id: vorsteuerId,
          userId: userId,
          datum: scanResult.datum,
          sollKonto: 1170,
          habenKonto: habenKonto,
          betrag: mwst,
          beschreibung:
              'Vorsteuer ${pos.mwstSatz}% - ${scanResult.geschaeft}',
          belegNr: '$belegNr-V',
        ));
        buchungIds.add(vorsteuerId);
      }
    }

    // 3. Beleg-Bild an erste Buchung anhängen
    if (belegBild != null &&
        belegDateiname != null &&
        belegDateityp != null &&
        buchungIds.isNotEmpty) {
      await _belegRepo.upload(
        buchungId: buchungIds.first,
        dateiname: belegDateiname,
        dateityp: belegDateityp,
        bytes: belegBild,
        belegQuelle: 'spesen_scan',
        beschreibung: '${scanResult.geschaeft} - ${scanResult.datum.day}.${scanResult.datum.month}.${scanResult.datum.year}',
      );
    }

    return buchungIds;
  }

  /// Konto-Nummer basierend auf Zahlungsmethode.
  static int _zahlungsKonto(String methode) {
    switch (methode) {
      case 'bar':
        return 1000; // Kasse
      case 'kreditkarte':
        return 2030; // Kontokorrent Kreditkarte
      default:
        return 1020; // Bank/Post (karte, twint, etc.)
    }
  }

  /// Schweizer 5-Rappen-Rundung.
  static double _runde5Rappen(double betrag) {
    return (betrag * 20).round() / 20;
  }
}
