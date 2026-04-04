import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:kmu_tool_app/data/models/lohnabrechnung.dart';
import 'package:kmu_tool_app/data/models/mitarbeiter.dart';
import 'package:kmu_tool_app/data/models/user_profile.dart';

class LohnabrechnungPdfService {
  static String _formatCHF(double amount) {
    return amount.toStringAsFixed(2);
  }

  static Future<void> generateAndPreview({
    required Lohnabrechnung abrechnung,
    required Mitarbeiter mitarbeiter,
    required UserProfile profile,
  }) async {
    final pdf = pw.Document(
      title: 'Lohnabrechnung ${abrechnung.periodeLabel}',
      author: profile.firmaName,
    );

    final headerStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final bodyStyle = const pw.TextStyle(fontSize: 9);
    final boldBody = pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    );
    final sectionStyle = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey700,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Firmen-Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(profile.firmaName, style: headerStyle),
                      if (profile.strasse != null)
                        pw.Text(
                          '${profile.strasse ?? ''} ${profile.hausnummer ?? ''}'.trim(),
                          style: bodyStyle,
                        ),
                      pw.Text(
                        '${profile.plz ?? ''} ${profile.ort ?? ''}'.trim(),
                        style: bodyStyle,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('LOHNABRECHNUNG',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text(abrechnung.periodeLabel, style: headerStyle),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Mitarbeiter-Info
              pw.Text('MITARBEITER', style: sectionStyle),
              pw.SizedBox(height: 4),
              pw.Text(mitarbeiter.displayName, style: headerStyle),
              if (mitarbeiter.ahvNummer != null)
                pw.Text('AHV-Nr.: ${mitarbeiter.ahvNummer}', style: bodyStyle),
              pw.Text(
                  'Pensum: ${(abrechnung.pensum * 100).round()}%',
                  style: bodyStyle),

              pw.SizedBox(height: 20),

              // Bruttolohn
              _tableRow('Bruttolohn', _formatCHF(abrechnung.bruttolohn),
                  boldBody, boldBody),
              pw.Divider(),

              pw.SizedBox(height: 8),
              pw.Text('ARBEITNEHMER-ABZUEGE', style: sectionStyle),
              pw.SizedBox(height: 4),

              if (abrechnung.ahvAn > 0)
                _tableRow('AHV/IV/EO', '- ${_formatCHF(abrechnung.ahvAn)}',
                    bodyStyle, bodyStyle),
              if (abrechnung.alvAn > 0)
                _tableRow('ALV', '- ${_formatCHF(abrechnung.alvAn)}',
                    bodyStyle, bodyStyle),
              if (abrechnung.uvgNbuAn > 0)
                _tableRow('UVG-NBU', '- ${_formatCHF(abrechnung.uvgNbuAn)}',
                    bodyStyle, bodyStyle),
              if (abrechnung.ktgAn > 0)
                _tableRow('KTG', '- ${_formatCHF(abrechnung.ktgAn)}',
                    bodyStyle, bodyStyle),
              if (abrechnung.bvgAn > 0)
                _tableRow('BVG', '- ${_formatCHF(abrechnung.bvgAn)}',
                    bodyStyle, bodyStyle),
              if (abrechnung.quellensteuer > 0)
                _tableRow('Quellensteuer',
                    '- ${_formatCHF(abrechnung.quellensteuer)}',
                    bodyStyle, bodyStyle),

              pw.Divider(),
              _tableRow('Total Abzuege',
                  '- ${_formatCHF(abrechnung.totalAnAbzuege)}',
                  boldBody, boldBody),

              if (abrechnung.kinderzulagen > 0) ...[
                pw.SizedBox(height: 8),
                pw.Text('ZULAGEN', style: sectionStyle),
                pw.SizedBox(height: 4),
                _tableRow('Kinderzulagen',
                    '+ ${_formatCHF(abrechnung.kinderzulagen)}',
                    bodyStyle, bodyStyle),
              ],

              pw.SizedBox(height: 12),
              pw.Divider(thickness: 2),
              _tableRow('NETTOLOHN', _formatCHF(abrechnung.nettolohn),
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 2),

              pw.SizedBox(height: 30),

              // AG-Kosten (intern)
              pw.Text('ARBEITGEBER-KOSTEN (INTERN)', style: sectionStyle),
              pw.SizedBox(height: 4),
              if (abrechnung.ahvAg > 0)
                _tableRow('AHV/IV/EO', _formatCHF(abrechnung.ahvAg),
                    bodyStyle, bodyStyle),
              if (abrechnung.alvAg > 0)
                _tableRow('ALV', _formatCHF(abrechnung.alvAg),
                    bodyStyle, bodyStyle),
              if (abrechnung.uvgBuAg > 0)
                _tableRow('UVG-BU', _formatCHF(abrechnung.uvgBuAg),
                    bodyStyle, bodyStyle),
              if (abrechnung.ktgAg > 0)
                _tableRow('KTG', _formatCHF(abrechnung.ktgAg),
                    bodyStyle, bodyStyle),
              if (abrechnung.bvgAg > 0)
                _tableRow('BVG', _formatCHF(abrechnung.bvgAg),
                    bodyStyle, bodyStyle),
              if (abrechnung.fakAg > 0)
                _tableRow('FAK', _formatCHF(abrechnung.fakAg),
                    bodyStyle, bodyStyle),
              pw.Divider(),
              _tableRow('Total AG-Kosten',
                  _formatCHF(abrechnung.totalAgKosten), boldBody, boldBody),

              pw.SizedBox(height: 30),

              // Footer
              pw.Text(
                'Status: ${abrechnung.statusLabel}',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Lohnabrechnung_${mitarbeiter.nachname}_${abrechnung.periodeLabel}',
    );
  }

  static pw.Widget _tableRow(
      String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: labelStyle),
          pw.Text(value, style: valueStyle),
        ],
      ),
    );
  }
}
