import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/data/models/offerte.dart';
import 'package:kmu_tool_app/data/models/offert_position.dart';
import 'package:kmu_tool_app/data/models/user_profile.dart';
import 'package:kmu_tool_app/data/models/kunde.dart';

/// Generates and previews an Offerte PDF document.
class OffertePdfService {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');

  /// Generate the PDF and open the preview / print dialog.
  static Future<void> generateAndPreview({
    required Offerte offerte,
    required List<OffertPosition> positionen,
    required Kunde kunde,
    required UserProfile profile,
  }) async {
    final pdf = pw.Document(
      title: 'Offerte ${offerte.offertNr ?? ""}',
      author: profile.firmaName,
    );

    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final bodyStyle = const pw.TextStyle(fontSize: 9);
    final smallStyle = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header: Company Info ───
              _buildHeader(profile, headerStyle, bodyStyle),
              pw.SizedBox(height: 30),

              // ─── Recipient: Kunde Address ───
              _buildRecipient(kunde, bodyStyle),
              pw.SizedBox(height: 30),

              // ─── Offerte Details ───
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Offerte',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Offerte-Nr: ${offerte.offertNr ?? "-"}',
                        style: headerStyle,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Datum: ${_dateFormat.format(offerte.datum)}',
                        style: bodyStyle,
                      ),
                      if (offerte.gueltigBis != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Gültig bis: ${_dateFormat.format(offerte.gueltigBis!)}',
                          style: bodyStyle,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // ─── Positions Table ───
              _buildPositionsTable(positionen, headerStyle, bodyStyle),
              pw.SizedBox(height: 16),

              // ─── Totals ───
              _buildTotals(offerte.totalNetto, offerte.mwstSatz,
                  offerte.mwstBetrag, offerte.totalBrutto, headerStyle, bodyStyle),
              pw.SizedBox(height: 24),

              // ─── Bemerkung ───
              if (offerte.bemerkung != null &&
                  offerte.bemerkung!.isNotEmpty) ...[
                pw.Text('Bemerkung', style: headerStyle),
                pw.SizedBox(height: 4),
                pw.Text(offerte.bemerkung!, style: bodyStyle),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // ─── Footer ───
              _buildFooter(profile, smallStyle),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
      name: 'Offerte_${offerte.offertNr ?? offerte.id}',
    );
  }

  static pw.Widget _buildHeader(
      UserProfile profile, pw.TextStyle headerStyle, pw.TextStyle bodyStyle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo area (placeholder)
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text('Logo', style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey500,
            )),
          ),
        ),
        // Company info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(profile.firmaName,
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            if (profile.strasse != null)
              pw.Text(profile.strasse!, style: bodyStyle),
            if (profile.plz != null || profile.ort != null)
              pw.Text(
                '${profile.plz ?? ''} ${profile.ort ?? ''}'.trim(),
                style: bodyStyle,
              ),
            if (profile.telefon != null)
              pw.Text('Tel: ${profile.telefon}', style: bodyStyle),
            pw.Text(profile.email, style: bodyStyle),
            if (profile.uidNummer != null)
              pw.Text('UID: ${profile.uidNummer}', style: bodyStyle),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildRecipient(Kunde kunde, pw.TextStyle bodyStyle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (kunde.firma != null && kunde.firma!.isNotEmpty)
          pw.Text(kunde.firma!,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        if (kunde.vorname != null || kunde.nachname.isNotEmpty)
          pw.Text(
            '${kunde.vorname ?? ''} ${kunde.nachname}'.trim(),
            style: bodyStyle,
          ),
        if (kunde.strasse != null)
          pw.Text(kunde.strasse!, style: bodyStyle),
        if (kunde.plz != null || kunde.ort != null)
          pw.Text(
            '${kunde.plz ?? ''} ${kunde.ort ?? ''}'.trim(),
            style: bodyStyle,
          ),
      ],
    );
  }

  static pw.Widget _buildPositionsTable(List<OffertPosition> positionen,
      pw.TextStyle headerStyle, pw.TextStyle bodyStyle) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
      headerStyle: headerStyle.copyWith(color: PdfColors.white, fontSize: 9),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
      headerAlignment: pw.Alignment.centerLeft,
      cellStyle: bodyStyle,
      cellAlignment: pw.Alignment.centerLeft,
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(4),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(65),
        5: const pw.FixedColumnWidth(75),
      },
      headers: ['Nr', 'Bezeichnung', 'Menge', 'Einheit', 'Preis', 'Betrag'],
      data: positionen.map((p) {
        return [
          '${p.positionNr}',
          p.bezeichnung,
          p.menge == p.menge.roundToDouble()
              ? p.menge.toInt().toString()
              : p.menge.toStringAsFixed(2),
          p.einheit ?? '',
          p.einheitspreis.toStringAsFixed(2),
          p.betrag.toStringAsFixed(2),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildTotals(
    double netto,
    double mwstSatz,
    double mwstBetrag,
    double brutto,
    pw.TextStyle headerStyle,
    pw.TextStyle bodyStyle,
  ) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _totalRow('Netto', _currencyFormat.format(netto), bodyStyle),
            pw.SizedBox(height: 4),
            _totalRow(
              'MWST (${mwstSatz.toStringAsFixed(1)}%)',
              _currencyFormat.format(mwstBetrag),
              bodyStyle,
            ),
            pw.Divider(color: PdfColors.grey400),
            _totalRow(
              'Brutto',
              _currencyFormat.format(brutto),
              headerStyle.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _totalRow(
      String label, String value, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }

  static pw.Widget _buildFooter(
      UserProfile profile, pw.TextStyle smallStyle) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(profile.firmaName, style: smallStyle),
          if (profile.telefon != null)
            pw.Text('Tel: ${profile.telefon}', style: smallStyle),
          pw.Text(profile.email, style: smallStyle),
          if (profile.iban != null)
            pw.Text('IBAN: ${profile.iban}', style: smallStyle),
        ],
      ),
    );
  }
}
