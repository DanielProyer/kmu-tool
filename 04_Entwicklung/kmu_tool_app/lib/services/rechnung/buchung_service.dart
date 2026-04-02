import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/rechnung.dart';
import 'package:kmu_tool_app/data/models/buchung.dart';
import 'package:kmu_tool_app/data/repositories/buchung_repository.dart';
import 'package:kmu_tool_app/data/repositories/rechnung_repository.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

/// Automatic booking service for invoices.
///
/// Handles the double-entry bookkeeping (doppelte Buchhaltung) entries that
/// must be created when invoices change status.
///
/// Swiss KMU Kontenrahmen accounts used:
/// - 1020  Bank (Bankguthaben)
/// - 1100  Debitoren (Forderungen aus Lieferungen und Leistungen)
/// - 1170  Vorsteuer MWST
/// - 2200  MWST (Geschuldete Mehrwertsteuer)
/// - 3000  Ertrag (Erloese aus Lieferungen und Leistungen)
class BuchungService {
  final BuchungRepository _buchungRepo = BuchungRepository();
  final RechnungRepository _rechnungRepo = RechnungRepository();
  static const _uuid = Uuid();

  String get _userId => SupabaseService.currentUser!.id;

  // ─── Kontonummern (Swiss KMU Kontenrahmen) ───
  static const int _kontoBank = 1020;
  static const int _kontoDebitoren = 1100;
  static const int _kontoMwst = 2200;
  static const int _kontoErtrag = 3000;

  /// Creates journal entries when an invoice is created or sent.
  ///
  /// Creates two bookings:
  /// 1. Soll 1100 (Debitoren) / Haben 3000 (Ertrag) - net amount
  ///    MWST-Code: UST_NORM (Umsatzsteuer Normalsatz)
  /// 2. Soll 1100 (Debitoren) / Haben 2200 (MWST)   - VAT amount
  ///    MWST-Code: UST_NORM
  Future<void> createBuchungenForRechnung(Rechnung rechnung) async {
    // Booking 1: Netto-Betrag -> Debitoren / Ertrag
    final buchungNetto = Buchung(
      id: _uuid.v4(),
      userId: _userId,
      datum: rechnung.datum,
      sollKonto: _kontoDebitoren,
      habenKonto: _kontoErtrag,
      betrag: rechnung.totalNetto,
      beschreibung:
          'Rechnung ${rechnung.rechnungsNr} - Ertrag (netto)',
      belegNr: rechnung.rechnungsNr,
      rechnungId: rechnung.id,
      mwstCode: 'UST_NORM',
      mwstSatz: rechnung.mwstSatz,
      mwstBetrag: rechnung.mwstBetrag,
    );
    await _buchungRepo.save(buchungNetto);

    // Booking 2: MWST-Betrag -> Debitoren / MWST
    if (rechnung.mwstBetrag > 0) {
      final buchungMwst = Buchung(
        id: _uuid.v4(),
        userId: _userId,
        datum: rechnung.datum,
        sollKonto: _kontoDebitoren,
        habenKonto: _kontoMwst,
        betrag: rechnung.mwstBetrag,
        beschreibung:
            'Rechnung ${rechnung.rechnungsNr} - MWST ${rechnung.mwstSatz.toStringAsFixed(1)}%',
        belegNr: rechnung.rechnungsNr,
        rechnungId: rechnung.id,
        mwstCode: 'UST_NORM',
        mwstSatz: rechnung.mwstSatz,
        mwstBetrag: rechnung.mwstBetrag,
      );
      await _buchungRepo.save(buchungMwst);
    }
  }

  /// Marks an invoice as paid and creates the corresponding booking.
  ///
  /// Creates one booking:
  /// - Soll 1020 (Bank) / Haben 1100 (Debitoren) - gross amount
  ///
  /// Also updates the invoice status to 'bezahlt'.
  Future<void> markAsBezahlt(String rechnungId) async {
    final rechnung = await _rechnungRepo.getById(rechnungId);
    if (rechnung == null) {
      throw Exception('Rechnung nicht gefunden: $rechnungId');
    }

    // Update invoice status
    await _rechnungRepo.updateStatus(rechnungId, 'bezahlt');

    // Create payment booking: Bank / Debitoren (kein MWST-Code bei Zahlung)
    final buchungZahlung = Buchung(
      id: _uuid.v4(),
      userId: _userId,
      datum: DateTime.now(),
      sollKonto: _kontoBank,
      habenKonto: _kontoDebitoren,
      betrag: rechnung.totalBrutto,
      beschreibung:
          'Zahlung Rechnung ${rechnung.rechnungsNr}',
      belegNr: rechnung.rechnungsNr,
      rechnungId: rechnung.id,
      mwstCode: 'OHNE',
    );
    await _buchungRepo.save(buchungZahlung);
  }

  /// Cancels (storniert) an invoice and creates reverse bookings.
  ///
  /// Reverses the original bookings:
  /// 1. Soll 3000 (Ertrag) / Haben 1100 (Debitoren) - net amount reversal
  /// 2. Soll 2200 (MWST)   / Haben 1100 (Debitoren) - VAT amount reversal
  ///
  /// Also updates the invoice status to 'storniert'.
  Future<void> storniereRechnung(String rechnungId) async {
    final rechnung = await _rechnungRepo.getById(rechnungId);
    if (rechnung == null) {
      throw Exception('Rechnung nicht gefunden: $rechnungId');
    }

    // Update invoice status
    await _rechnungRepo.updateStatus(rechnungId, 'storniert');

    // Reverse booking 1: Ertrag / Debitoren (net reversal)
    final stornoNetto = Buchung(
      id: _uuid.v4(),
      userId: _userId,
      datum: DateTime.now(),
      sollKonto: _kontoErtrag,
      habenKonto: _kontoDebitoren,
      betrag: rechnung.totalNetto,
      beschreibung:
          'Storno Rechnung ${rechnung.rechnungsNr} - Ertrag (netto)',
      belegNr: 'ST-${rechnung.rechnungsNr}',
      rechnungId: rechnung.id,
      mwstCode: 'UST_NORM',
      mwstSatz: rechnung.mwstSatz,
      mwstBetrag: rechnung.mwstBetrag,
    );
    await _buchungRepo.save(stornoNetto);

    // Reverse booking 2: MWST / Debitoren (VAT reversal)
    if (rechnung.mwstBetrag > 0) {
      final stornoMwst = Buchung(
        id: _uuid.v4(),
        userId: _userId,
        datum: DateTime.now(),
        sollKonto: _kontoMwst,
        habenKonto: _kontoDebitoren,
        betrag: rechnung.mwstBetrag,
        beschreibung:
            'Storno Rechnung ${rechnung.rechnungsNr} - MWST',
        belegNr: 'ST-${rechnung.rechnungsNr}',
        rechnungId: rechnung.id,
        mwstCode: 'UST_NORM',
        mwstSatz: rechnung.mwstSatz,
        mwstBetrag: rechnung.mwstBetrag,
      );
      await _buchungRepo.save(stornoMwst);
    }

    // If the invoice was already paid, also reverse the payment booking
    if (rechnung.status == 'bezahlt') {
      final stornoZahlung = Buchung(
        id: _uuid.v4(),
        userId: _userId,
        datum: DateTime.now(),
        sollKonto: _kontoDebitoren,
        habenKonto: _kontoBank,
        betrag: rechnung.totalBrutto,
        beschreibung:
            'Storno Zahlung Rechnung ${rechnung.rechnungsNr}',
        belegNr: 'ST-${rechnung.rechnungsNr}',
        rechnungId: rechnung.id,
        mwstCode: 'OHNE',
      );
      await _buchungRepo.save(stornoZahlung);
    }
  }
}
