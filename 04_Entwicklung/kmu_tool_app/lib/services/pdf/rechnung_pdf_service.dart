import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/data/models/rechnung.dart';
import 'package:kmu_tool_app/data/models/rechnungs_position.dart';
import 'package:kmu_tool_app/data/models/user_profile.dart';
import 'package:kmu_tool_app/data/models/kunde.dart';

/// Generates a Swiss QR-Rechnung PDF with invoice content and QR payment slip.
class RechnungPdfService {
  static final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');
  static final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');

  // Swiss QR bill dimensions (in mm, converted to pdf points)
  static const double _mmToPt = PdfPageFormat.mm;
  static const double _qrSlipHeight = 105 * _mmToPt;
  static const double _empfangsscheinWidth = 62 * _mmToPt;
  static const double _zahlteilWidth = 148 * _mmToPt; // rest of A4 width

  /// Generate the PDF and open the preview / print dialog.
  static Future<void> generateAndPreview({
    required Rechnung rechnung,
    required List<RechnungsPosition> positionen,
    required Kunde kunde,
    required UserProfile profile,
  }) async {
    final pdf = pw.Document(
      title: 'Rechnung ${rechnung.rechnungsNr}',
      author: profile.firmaName,
    );

    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final bodyStyle = const pw.TextStyle(fontSize: 9);
    final smallStyle = pw.TextStyle(fontSize: 8, color: PdfColors.grey700);
    final tinyStyle = pw.TextStyle(fontSize: 6, color: PdfColors.grey600);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(
          left: 40,
          right: 40,
          top: 40,
          bottom: 0, // We need full control at the bottom for QR slip
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Invoice Content Area ───
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Header: Company info
                    _buildHeader(profile, headerStyle, bodyStyle),
                    pw.SizedBox(height: 30),

                    // Recipient
                    _buildRecipient(kunde, bodyStyle),
                    pw.SizedBox(height: 30),

                    // Invoice title and details
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Rechnung',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Rechnungs-Nr: ${rechnung.rechnungsNr}',
                              style: headerStyle,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Datum: ${_dateFormat.format(rechnung.datum)}',
                              style: bodyStyle,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Fällig am: ${_dateFormat.format(rechnung.faelligAm)}',
                              style: bodyStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),

                    // Positions table
                    _buildPositionsTable(positionen, headerStyle, bodyStyle),
                    pw.SizedBox(height: 16),

                    // Totals
                    _buildTotals(
                      rechnung.totalNetto,
                      rechnung.mwstSatz,
                      rechnung.mwstBetrag,
                      rechnung.totalBrutto,
                      headerStyle,
                      bodyStyle,
                    ),
                    pw.SizedBox(height: 16),

                    // Payment info
                    pw.Text(
                      'Zahlbar innert 30 Tagen.',
                      style: bodyStyle,
                    ),
                    if (rechnung.qrReferenz != null &&
                        rechnung.qrReferenz!.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Referenz: ${rechnung.qrReferenz}',
                        style: bodyStyle,
                      ),
                    ],
                  ],
                ),
              ),

              // ─── QR Payment Slip (Bottom 105mm) ───
              _buildQrPaymentSlip(
                rechnung: rechnung,
                profile: profile,
                kunde: kunde,
                headerStyle: headerStyle,
                bodyStyle: bodyStyle,
                smallStyle: smallStyle,
                tinyStyle: tinyStyle,
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => pdf.save(),
      name: 'Rechnung_${rechnung.rechnungsNr}',
    );
  }

  // ─── Header ───

  static pw.Widget _buildHeader(
      UserProfile profile, pw.TextStyle headerStyle, pw.TextStyle bodyStyle) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo placeholder
        pw.Container(
          width: 60,
          height: 60,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              'Logo',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
            ),
          ),
        ),
        // Company details
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

  // ─── Recipient ───

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
        if (kunde.strasse != null) pw.Text(kunde.strasse!, style: bodyStyle),
        if (kunde.plz != null || kunde.ort != null)
          pw.Text(
            '${kunde.plz ?? ''} ${kunde.ort ?? ''}'.trim(),
            style: bodyStyle,
          ),
      ],
    );
  }

  // ─── Positions Table ───

  static pw.Widget _buildPositionsTable(List<RechnungsPosition> positionen,
      pw.TextStyle headerStyle, pw.TextStyle bodyStyle) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder(
        bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        horizontalInside:
            pw.BorderSide(color: PdfColors.grey200, width: 0.5),
      ),
      headerStyle:
          headerStyle.copyWith(color: PdfColors.white, fontSize: 9),
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
          p.einheit,
          p.einheitspreis.toStringAsFixed(2),
          p.betrag.toStringAsFixed(2),
        ];
      }).toList(),
    );
  }

  // ─── Totals Block ───

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

  // ─── QR Payment Slip (Swiss QR Bill) ───
  // Layout according to Swiss Payment Standards.
  // The slip occupies the bottom 105mm of the A4 page.
  // Left part: Empfangsschein (62mm width)
  // Right part: Zahlteil (148mm width) with QR code area

  static pw.Widget _buildQrPaymentSlip({
    required Rechnung rechnung,
    required UserProfile profile,
    required Kunde kunde,
    required pw.TextStyle headerStyle,
    required pw.TextStyle bodyStyle,
    required pw.TextStyle smallStyle,
    required pw.TextStyle tinyStyle,
  }) {
    final qrTitleStyle = pw.TextStyle(
      fontSize: 11,
      fontWeight: pw.FontWeight.bold,
    );
    final qrHeaderStyle = pw.TextStyle(
      fontSize: 6,
      fontWeight: pw.FontWeight.bold,
    );
    final qrBodyStyle = const pw.TextStyle(fontSize: 8);
    final qrSmallStyle = const pw.TextStyle(fontSize: 7);
    final qrAmountStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    final empfaengerLines = <String>[
      profile.firmaName,
      if (profile.strasse != null) profile.strasse!,
      '${profile.plz ?? ''} ${profile.ort ?? ''}'.trim(),
    ];

    final zahlerLines = <String>[
      if (kunde.firma != null && kunde.firma!.isNotEmpty) kunde.firma!,
      '${kunde.vorname ?? ''} ${kunde.nachname}'.trim(),
      if (kunde.strasse != null) kunde.strasse!,
      '${kunde.plz ?? ''} ${kunde.ort ?? ''}'.trim(),
    ];

    return pw.Container(
      height: _qrSlipHeight,
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.black,
            width: 0.5,
            style: pw.BorderStyle.dashed,
          ),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ─── Empfangsschein (left, 62mm) ───
          pw.Container(
            width: _empfangsscheinWidth,
            padding: const pw.EdgeInsets.all(5 * _mmToPt),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(
                  color: PdfColors.black,
                  width: 0.5,
                  style: pw.BorderStyle.dashed,
                ),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Empfangsschein', style: qrTitleStyle),
                pw.SizedBox(height: 3 * _mmToPt),

                // Konto / Zahlbar an
                pw.Text('Konto / Zahlbar an', style: qrHeaderStyle),
                pw.SizedBox(height: 1 * _mmToPt),
                if (profile.iban != null)
                  pw.Text(profile.iban!, style: qrSmallStyle),
                ...empfaengerLines
                    .map((l) => pw.Text(l, style: qrSmallStyle)),
                pw.SizedBox(height: 3 * _mmToPt),

                // Referenz
                if (rechnung.qrReferenz != null &&
                    rechnung.qrReferenz!.isNotEmpty) ...[
                  pw.Text('Referenz', style: qrHeaderStyle),
                  pw.SizedBox(height: 1 * _mmToPt),
                  pw.Text(rechnung.qrReferenz!, style: qrSmallStyle),
                  pw.SizedBox(height: 3 * _mmToPt),
                ],

                // Zahlbar durch
                pw.Text('Zahlbar durch', style: qrHeaderStyle),
                pw.SizedBox(height: 1 * _mmToPt),
                ...zahlerLines.map((l) => pw.Text(l, style: qrSmallStyle)),

                pw.Spacer(),

                // Währung / Betrag
                pw.Row(
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Währung', style: qrHeaderStyle),
                        pw.Text('CHF', style: qrBodyStyle),
                      ],
                    ),
                    pw.SizedBox(width: 3 * _mmToPt),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Betrag', style: qrHeaderStyle),
                        pw.Text(rechnung.totalBrutto.toStringAsFixed(2),
                            style: qrBodyStyle),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 2 * _mmToPt),
                pw.Text('Annahmestelle', style: qrHeaderStyle),
              ],
            ),
          ),

          // ─── Zahlteil (right, 148mm) ───
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(5 * _mmToPt),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Zahlteil', style: qrTitleStyle),
                  pw.SizedBox(height: 3 * _mmToPt),

                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // QR Code placeholder
                      pw.Container(
                        width: 46 * _mmToPt,
                        height: 46 * _mmToPt,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: PdfColors.grey400, width: 1),
                        ),
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              'QR',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey500,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Swiss QR Code',
                              style: pw.TextStyle(
                                fontSize: 7,
                                color: PdfColors.grey500,
                              ),
                            ),
                            pw.Text(
                              '(MVP Placeholder)',
                              style: pw.TextStyle(
                                fontSize: 6,
                                color: PdfColors.grey400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      pw.SizedBox(width: 5 * _mmToPt),

                      // Right column: amount + info
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // Währung / Betrag
                            pw.Row(
                              children: [
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Währung',
                                        style: qrHeaderStyle),
                                    pw.Text('CHF', style: qrAmountStyle),
                                  ],
                                ),
                                pw.SizedBox(width: 5 * _mmToPt),
                                pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text('Betrag',
                                        style: qrHeaderStyle),
                                    pw.Text(
                                      rechnung.totalBrutto
                                          .toStringAsFixed(2),
                                      style: qrAmountStyle,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3 * _mmToPt),

                  // Konto / Zahlbar an
                  pw.Text('Konto / Zahlbar an', style: qrHeaderStyle),
                  pw.SizedBox(height: 1 * _mmToPt),
                  if (profile.iban != null)
                    pw.Text(profile.iban!, style: qrBodyStyle),
                  ...empfaengerLines
                      .map((l) => pw.Text(l, style: qrBodyStyle)),
                  pw.SizedBox(height: 3 * _mmToPt),

                  // Referenz
                  if (rechnung.qrReferenz != null &&
                      rechnung.qrReferenz!.isNotEmpty) ...[
                    pw.Text('Referenz', style: qrHeaderStyle),
                    pw.SizedBox(height: 1 * _mmToPt),
                    pw.Text(rechnung.qrReferenz!, style: qrBodyStyle),
                    pw.SizedBox(height: 3 * _mmToPt),
                  ],

                  // Zusätzliche Informationen
                  pw.Text('Zusätzliche Informationen', style: qrHeaderStyle),
                  pw.SizedBox(height: 1 * _mmToPt),
                  pw.Text(rechnung.rechnungsNr, style: qrBodyStyle),
                  pw.SizedBox(height: 3 * _mmToPt),

                  // Zahlbar durch
                  pw.Text('Zahlbar durch', style: qrHeaderStyle),
                  pw.SizedBox(height: 1 * _mmToPt),
                  ...zahlerLines.map((l) => pw.Text(l, style: qrBodyStyle)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
