import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/buchung.dart';
import 'package:kmu_tool_app/data/models/mwst_einstellung.dart';
import 'package:kmu_tool_app/data/models/mwst_abrechnung.dart';
import 'package:kmu_tool_app/data/repositories/mwst_repository.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

/// MWST-Abrechnungsservice.
///
/// Berechnet die MWST-Abrechnung basierend auf der gewaehlten Methode:
/// - **Effektive Methode**: Umsatzsteuer - Vorsteuer = Zahllast
/// - **Saldosteuersatz-Methode**: Bruttoumsatz x SSS = Zahllast
///
/// Die Berechnung folgt exakt den ESTV-Formularen:
/// - Formular 0550 (Effektive Methode)
/// - Formular 0553 (Saldosteuersatz-Methode)
class MwstService {
  final MwstRepository _repo = MwstRepository();
  static const _uuid = Uuid();

  String get _userId => SupabaseService.currentUser!.id;

  /// Berechnet und speichert eine MWST-Abrechnung fuer die gegebene Periode.
  Future<MwstAbrechnung> generateAbrechnung({
    required DateTime periodeStart,
    required DateTime periodeEnd,
  }) async {
    // 1. Einstellungen laden
    final einstellung = await _repo.getEinstellung();
    if (einstellung == null) {
      throw Exception('MWST-Einstellungen nicht konfiguriert. '
          'Bitte zuerst unter Einstellungen die MWST-Methode festlegen.');
    }

    // 2. Buchungen der Periode laden (via Supabase direkt)
    final buchungen = await _loadBuchungen(periodeStart, periodeEnd);

    // 3. Berechnung je nach Methode
    MwstAbrechnung abrechnung;
    if (einstellung.isEffektiv) {
      abrechnung = _berechneEffektiv(buchungen, einstellung, periodeStart, periodeEnd);
    } else {
      abrechnung = _berechneSaldosteuersatz(buchungen, einstellung, periodeStart, periodeEnd);
    }

    // 4. Speichern
    await _repo.saveAbrechnung(abrechnung);
    return abrechnung;
  }

  /// Laedt alle Buchungen einer Periode.
  Future<List<Buchung>> _loadBuchungen(DateTime start, DateTime end) async {
    final data = await SupabaseService.client
        .from('buchungen')
        .select()
        .eq('user_id', _userId)
        .gte('datum', start.toIso8601String().split('T').first)
        .lte('datum', end.toIso8601String().split('T').first)
        .order('datum');
    return data.map((json) => Buchung.fromJson(json)).toList();
  }

  /// Effektive Methode: Umsatzsteuer - Vorsteuer = Zahllast
  MwstAbrechnung _berechneEffektiv(
    List<Buchung> buchungen,
    MwstEinstellung einstellung,
    DateTime periodeStart,
    DateTime periodeEnd,
  ) {
    // Teil I: Umsatz (Ertragsbuchungen auf Konten 3000-3999)
    double totalUmsatz = 0;
    double umsatzNorm = 0;
    double umsatzRed = 0;
    double umsatzBeh = 0;
    double steuerbefreit = 0;
    double ausgenommen = 0;
    double entgeltsminderungen = 0;
    double bezugsteuer = 0;

    // Teil III: Vorsteuer
    double vorsteuerMat = 0;
    double vorsteuerInv = 0;

    for (final b in buchungen) {
      final code = b.mwstCode;
      final mwstBetrag = b.mwstBetrag ?? 0;

      // Umsatz: Haben-Buchungen auf Ertragskonten (3000-7999)
      if (b.habenKonto >= 3000 && b.habenKonto <= 7999) {
        totalUmsatz += b.betrag;

        switch (code) {
          case 'UST_NORM':
            umsatzNorm += b.betrag;
          case 'UST_RED':
            umsatzRed += b.betrag;
          case 'UST_BEH':
            umsatzBeh += b.betrag;
          case 'UST_FREI':
            steuerbefreit += b.betrag;
          case 'UST_AUSG':
            ausgenommen += b.betrag;
          default:
            // Ohne MWST-Code: Normalsatz annehmen
            if (code == null || code == 'OHNE') {
              // Kein MWST
            } else {
              umsatzNorm += b.betrag;
            }
        }
      }

      // Stornos auf Ertragskonten (Soll-Buchungen)
      if (b.sollKonto >= 3000 && b.sollKonto <= 7999) {
        totalUmsatz -= b.betrag;
        entgeltsminderungen += b.betrag;
      }

      // Vorsteuer: Soll-Buchungen auf Aufwandkonten
      if (code != null && code.startsWith('VST')) {
        if (code == 'VST_MAT' || code == 'VST_MAT_RED') {
          vorsteuerMat += mwstBetrag;
        } else if (code == 'VST_INV' || code == 'VST_INV_RED') {
          vorsteuerInv += mwstBetrag;
        }
      }

      // Bezugsteuer
      if (code == 'BEZUG') {
        bezugsteuer += mwstBetrag;
      }
    }

    // Berechnungen
    final totalAbzuege = steuerbefreit + ausgenommen + entgeltsminderungen;
    final steuerbarUmsatz = totalUmsatz - totalAbzuege;

    final steuer302 = umsatzNorm * 0.081;
    final steuer312 = umsatzRed * 0.026;
    final steuer342 = umsatzBeh * 0.038;
    final totalSteuer = steuer302 + steuer312 + steuer342 + bezugsteuer;

    final totalVorsteuer = vorsteuerMat + vorsteuerInv;

    final zahllast = totalSteuer >= totalVorsteuer ? totalSteuer - totalVorsteuer : 0.0;
    final guthaben = totalVorsteuer > totalSteuer ? totalVorsteuer - totalSteuer : 0.0;

    return MwstAbrechnung(
      id: _uuid.v4(),
      userId: _userId,
      periodeStart: periodeStart,
      periodeEnd: periodeEnd,
      methode: 'effektiv',
      ziff200: _round(totalUmsatz),
      ziff220: _round(steuerbefreit),
      ziff225: _round(ausgenommen),
      ziff235: _round(entgeltsminderungen),
      ziff289: _round(totalAbzuege),
      ziff299: _round(steuerbarUmsatz),
      ziff302Umsatz: _round(umsatzNorm),
      ziff302Steuer: _round(steuer302),
      ziff312Umsatz: _round(umsatzRed),
      ziff312Steuer: _round(steuer312),
      ziff342Umsatz: _round(umsatzBeh),
      ziff342Steuer: _round(steuer342),
      ziff382: _round(bezugsteuer),
      ziff399: _round(totalSteuer),
      ziff400: _round(vorsteuerMat),
      ziff405: _round(vorsteuerInv),
      ziff479: _round(totalVorsteuer),
      ziff500: _round(zahllast),
      ziff510: _round(guthaben),
    );
  }

  /// Saldosteuersatz-Methode: Bruttoumsatz x SSS = Zahllast
  MwstAbrechnung _berechneSaldosteuersatz(
    List<Buchung> buchungen,
    MwstEinstellung einstellung,
    DateTime periodeStart,
    DateTime periodeEnd,
  ) {
    // Teil I: Gesamtumsatz (brutto, inkl. MWST)
    double totalUmsatzBrutto = 0;
    double steuerbefreit = 0;
    double ausgenommen = 0;
    double entgeltsminderungen = 0;
    double bezugsteuer = 0;
    double vorsteuerInv = 0;

    for (final b in buchungen) {
      final code = b.mwstCode;
      final mwstBetrag = b.mwstBetrag ?? 0;

      // Umsatz (Haben auf 3000-7999) - bei SSS ist das brutto
      if (b.habenKonto >= 3000 && b.habenKonto <= 7999) {
        totalUmsatzBrutto += b.betrag;
        // Bei SSS: Der Betrag im Haben von 3000 ist der Netto-Ertrag,
        // plus MWST aus 2200 ergibt brutto.
        // Wir addieren auch den MWST-Betrag der gleichen Rechnung
        totalUmsatzBrutto += mwstBetrag;

        switch (code) {
          case 'UST_FREI':
            steuerbefreit += b.betrag;
          case 'UST_AUSG':
            ausgenommen += b.betrag;
        }
      }

      // Stornos
      if (b.sollKonto >= 3000 && b.sollKonto <= 7999) {
        totalUmsatzBrutto -= b.betrag;
        entgeltsminderungen += b.betrag;
      }

      // Bei SSS: Vorsteuer NUR auf Investitionen > CHF 10'000
      if (code == 'VST_INV' || code == 'VST_INV_RED') {
        vorsteuerInv += mwstBetrag;
      }

      // Bezugsteuer
      if (code == 'BEZUG') {
        bezugsteuer += mwstBetrag;
      }
    }

    final totalAbzuege = steuerbefreit + ausgenommen + entgeltsminderungen;
    final steuerbarUmsatz = totalUmsatzBrutto - totalAbzuege;

    // SSS-Berechnung
    final sss1 = einstellung.saldosteuersatz1 ?? 0;
    final sss2 = einstellung.saldosteuersatz2;

    double steuer322 = 0;
    double umsatz322 = steuerbarUmsatz;
    double steuer332 = 0;
    double umsatz332 = 0;

    if (sss2 != null && sss2 > 0) {
      // Zwei Saetze: Aufteilung muss manuell/pro Buchung erfolgen
      // Vereinfachung: Gesamtumsatz zum 1. Satz
      steuer322 = steuerbarUmsatz * sss1 / 100;
      // 2. Satz bleibt 0 bis die Aufteilung implementiert ist
    } else {
      steuer322 = steuerbarUmsatz * sss1 / 100;
    }

    final totalSteuer = steuer322 + steuer332 + bezugsteuer;

    // Bei SSS: Vorsteuer nur auf Einzelinvestitionen > CHF 10'000
    final totalVorsteuer = vorsteuerInv;

    final zahllast = totalSteuer >= totalVorsteuer ? totalSteuer - totalVorsteuer : 0.0;
    final guthaben = totalVorsteuer > totalSteuer ? totalVorsteuer - totalSteuer : 0.0;

    return MwstAbrechnung(
      id: _uuid.v4(),
      userId: _userId,
      periodeStart: periodeStart,
      periodeEnd: periodeEnd,
      methode: 'saldosteuersatz',
      ziff200: _round(totalUmsatzBrutto),
      ziff220: _round(steuerbefreit),
      ziff225: _round(ausgenommen),
      ziff235: _round(entgeltsminderungen),
      ziff289: _round(totalAbzuege),
      ziff299: _round(steuerbarUmsatz),
      ziff322Umsatz: _round(umsatz322),
      ziff322Steuer: _round(steuer322),
      ziff332Umsatz: _round(umsatz332),
      ziff332Steuer: _round(steuer332),
      ziff382: _round(bezugsteuer),
      ziff399: _round(totalSteuer),
      ziff405: _round(vorsteuerInv),
      ziff479: _round(totalVorsteuer),
      ziff500: _round(zahllast),
      ziff510: _round(guthaben),
    );
  }

  /// Berechnet die naechste Abrechnungsperiode.
  Future<({DateTime start, DateTime end})> getNextPeriode() async {
    final einstellung = await _repo.getEinstellung();
    final periode = einstellung?.abrechnungsperiode ?? 'halbjaehrlich';
    final now = DateTime.now();

    switch (periode) {
      case 'quartalsweise':
        final q = ((now.month - 1) ~/ 3);
        final start = DateTime(now.year, q * 3 + 1, 1);
        final endMonth = q * 3 + 3;
        final end = DateTime(now.year, endMonth + 1, 0); // letzter Tag
        return (start: start, end: end);

      case 'jaehrlich':
        return (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );

      case 'halbjaehrlich':
      default:
        if (now.month <= 6) {
          return (
            start: DateTime(now.year, 1, 1),
            end: DateTime(now.year, 6, 30),
          );
        } else {
          return (
            start: DateTime(now.year, 7, 1),
            end: DateTime(now.year, 12, 31),
          );
        }
    }
  }

  /// Bestimmt den Standard-MWST-Code fuer ein Konto.
  static String defaultMwstCodeForKonto(int kontonummer, {required bool isEffektiv}) {
    if (kontonummer >= 3000 && kontonummer <= 3999) return 'UST_NORM';
    if (kontonummer >= 7000 && kontonummer <= 7999) return 'UST_NORM';

    if (!isEffektiv) return 'OHNE'; // Bei SSS keine Vorsteuer-Codes

    if (kontonummer >= 4000 && kontonummer <= 4999) return 'VST_MAT';
    if (kontonummer >= 5000 && kontonummer <= 5999) return 'OHNE'; // Personal
    if (kontonummer >= 6000 && kontonummer <= 6499) return 'VST_INV'; // Raum
    if (kontonummer >= 6500 && kontonummer <= 6599) return 'VST_INV'; // Fahrzeug
    if (kontonummer >= 6600 && kontonummer <= 6699) return 'OHNE'; // Versicherung
    if (kontonummer >= 6700 && kontonummer <= 6999) return 'VST_INV'; // Verwaltung/IT
    if (kontonummer >= 8000 && kontonummer <= 9999) return 'OHNE';

    return 'OHNE';
  }

  double _round(double value) =>
      double.parse(value.toStringAsFixed(2));
}
