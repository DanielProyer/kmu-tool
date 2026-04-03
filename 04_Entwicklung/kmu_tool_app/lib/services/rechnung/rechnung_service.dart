import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/rechnung.dart';
import 'package:kmu_tool_app/data/models/rechnungs_position.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_repository.dart';
import 'package:kmu_tool_app/data/repositories/rechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/rechnungs_position_repository.dart';
import 'package:kmu_tool_app/data/repositories/zeiterfassung_repository.dart';
import 'package:kmu_tool_app/services/rechnung/buchung_service.dart';
import '../auth/betrieb_service.dart';

/// Service for creating invoices from Auftraege (jobs).
///
/// Gathers time tracking entries (Zeiterfassungen) and generates an invoice
/// with line items, totals, and automatic bookkeeping entries.
class RechnungService {
  final RechnungRepository _rechnungRepo = RechnungRepository();
  final RechnungsPositionRepository _positionRepo =
      RechnungsPositionRepository();
  final BuchungService _buchungService = BuchungService();
  static const _uuid = Uuid();

  /// Default MWST rate for Switzerland (as of 2024).
  static const double _defaultMwstSatz = 8.1;

  /// Default hourly rate in CHF (can be overridden per Auftrag in future).
  static const double _defaultStundenansatz = 85.0;

  /// Default payment term in days.
  static const int _zahlungsfristTage = 30;

  /// Creates a new Rechnung from an Auftrag.
  ///
  /// This method:
  /// 1. Loads the Auftrag and its Zeiterfassungen
  /// 2. Calculates total hours worked
  /// 3. Creates invoice positions (Arbeitszeit line item)
  /// 4. Calculates MWST and totals
  /// 5. Generates a unique Rechnungs-Nr (RE-YYYY-NNN)
  /// 6. Saves the Rechnung and positions
  /// 7. Creates accounting entries via BuchungService
  ///
  /// [auftragId] The ID of the Auftrag to invoice.
  /// [stundenansatz] Optional hourly rate override (default 85 CHF).
  /// [zusatzPositionen] Optional additional manual positions to include.
  ///
  /// Returns the created [Rechnung].
  Future<Rechnung> createFromAuftrag(
    String auftragId, {
    double? stundenansatz,
    List<ManuellePosition>? zusatzPositionen,
  }) async {
    final userId = await BetriebService.getDataOwnerId();
    final rate = stundenansatz ?? _defaultStundenansatz;

    // 1. Load Auftrag
    final auftrag = await AuftragRepository.getById(auftragId);
    if (auftrag == null) {
      throw Exception('Auftrag nicht gefunden: $auftragId');
    }

    // 2. Load Zeiterfassungen for this Auftrag
    final zeiterfassungen =
        await ZeiterfassungRepository.getByAuftrag(auftragId);

    // 3. Calculate total hours
    int totalMinuten = 0;
    for (final ze in zeiterfassungen) {
      totalMinuten += ze.dauerMinuten ?? 0;
    }
    final totalStunden = totalMinuten / 60.0;

    // 4. Build positions
    final positionen = <RechnungsPosition>[];
    final rechnungId = _uuid.v4();
    int posNr = 1;

    // Position 1: Arbeitszeit
    if (totalStunden > 0) {
      final arbeitszeitBetrag = totalStunden * rate;
      positionen.add(RechnungsPosition(
        id: _uuid.v4(),
        rechnungId: rechnungId,
        positionNr: posNr++,
        bezeichnung: 'Arbeitszeit',
        menge: double.parse(totalStunden.toStringAsFixed(2)),
        einheit: 'Stunden',
        einheitspreis: rate,
        betrag: double.parse(arbeitszeitBetrag.toStringAsFixed(2)),
      ));
    }

    // Additional manual positions
    if (zusatzPositionen != null) {
      for (final zp in zusatzPositionen) {
        final betrag = zp.menge * zp.einheitspreis;
        positionen.add(RechnungsPosition(
          id: _uuid.v4(),
          rechnungId: rechnungId,
          positionNr: posNr++,
          bezeichnung: zp.bezeichnung,
          menge: zp.menge,
          einheit: zp.einheit,
          einheitspreis: zp.einheitspreis,
          betrag: double.parse(betrag.toStringAsFixed(2)),
        ));
      }
    }

    // 5. Calculate totals
    double totalNetto = 0;
    for (final p in positionen) {
      totalNetto += p.betrag;
    }
    totalNetto = double.parse(totalNetto.toStringAsFixed(2));
    final mwstBetrag =
        double.parse((totalNetto * _defaultMwstSatz / 100).toStringAsFixed(2));
    final totalBrutto =
        double.parse((totalNetto + mwstBetrag).toStringAsFixed(2));

    // 6. Generate Rechnungs-Nr: RE-YYYY-NNN
    final rechnungsNr = await _generateRechnungsNr();

    // 7. Generate QR reference (simplified for MVP)
    final qrReferenz = _generateQrReferenz(rechnungsNr);

    // 8. Build the Rechnung
    final now = DateTime.now();
    final rechnung = Rechnung(
      id: rechnungId,
      userId: userId,
      kundeId: auftrag.kundeId,
      auftragId: auftragId,
      rechnungsNr: rechnungsNr,
      datum: now,
      faelligAm: now.add(const Duration(days: _zahlungsfristTage)),
      status: 'entwurf',
      totalNetto: totalNetto,
      mwstSatz: _defaultMwstSatz,
      mwstBetrag: mwstBetrag,
      totalBrutto: totalBrutto,
      qrReferenz: qrReferenz,
    );

    // 9. Save to database
    await _rechnungRepo.save(rechnung);
    await _positionRepo.saveAll(rechnungId, positionen);

    // 10. Create bookkeeping entries
    await _buchungService.createBuchungenForRechnung(rechnung);

    return rechnung;
  }

  /// Generates a sequential invoice number in the format RE-YYYY-NNN.
  ///
  /// Fetches all existing invoices for the current year and increments
  /// the counter.
  Future<String> _generateRechnungsNr() async {
    final year = DateTime.now().year;
    final prefix = 'RE-$year-';

    // Get all invoices to find the highest number for this year
    final alleRechnungen = await _rechnungRepo.getAll();
    int maxNr = 0;

    for (final r in alleRechnungen) {
      if (r.rechnungsNr.startsWith(prefix)) {
        final nrStr = r.rechnungsNr.substring(prefix.length);
        final nr = int.tryParse(nrStr);
        if (nr != null && nr > maxNr) {
          maxNr = nr;
        }
      }
    }

    final nextNr = maxNr + 1;
    return '$prefix${nextNr.toString().padLeft(3, '0')}';
  }

  /// Generates a simplified QR reference for the Swiss QR bill.
  ///
  /// In a production system, this would follow the ISO 11649 Creditor Reference
  /// or the Swiss QR-IBAN format with a structured reference (QRR).
  /// For MVP, we generate a unique 26-digit number based on the invoice number.
  String _generateQrReferenz(String rechnungsNr) {
    // Extract numbers from rechnungsNr (e.g., RE-2026-001 -> 20260001)
    final digits =
        rechnungsNr.replaceAll(RegExp(r'[^0-9]'), '').padLeft(20, '0');
    // Create a 26-char reference with check digit placeholder
    final base = digits.padLeft(26, '0');
    // In production, compute mod 10 recursive check digit
    return base.substring(0, 26);
  }
}

/// A manual position to add to an invoice (e.g. material costs).
class ManuellePosition {
  final String bezeichnung;
  final double menge;
  final String einheit;
  final double einheitspreis;

  const ManuellePosition({
    required this.bezeichnung,
    required this.menge,
    required this.einheit,
    required this.einheitspreis,
  });
}
