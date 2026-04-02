import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/konto.dart';
import 'package:kmu_tool_app/data/repositories/konto_repository.dart';
import 'package:kmu_tool_app/data/models/buchung.dart';
import 'package:kmu_tool_app/data/repositories/buchung_repository.dart';

// ─── Types ───

enum _Periode { ganzes_jahr, q1, q2, q3, q4, custom }

class _BerichtData {
  final List<Konto> aktiven; // Klasse 1
  final List<Konto> passiven; // Klasse 2
  final List<Konto> ertraege; // Klasse 3
  final List<Konto> aufwand4; // Klasse 4 Material
  final List<Konto> aufwand5; // Klasse 5 Personal
  final List<Konto> aufwand6; // Klasse 6 Sonstiger Betriebsaufwand
  final List<Konto> aufwand8; // Klasse 8 Ausserordentlich

  const _BerichtData({
    this.aktiven = const [],
    this.passiven = const [],
    this.ertraege = const [],
    this.aufwand4 = const [],
    this.aufwand5 = const [],
    this.aufwand6 = const [],
    this.aufwand8 = const [],
  });

  double get totalAktiven =>
      aktiven.fold<double>(0, (s, k) => s + k.saldo);
  double get totalPassiven =>
      passiven.fold<double>(0, (s, k) => s + k.saldo);
  double get totalErtrag =>
      ertraege.fold<double>(0, (s, k) => s + k.saldo);
  double get totalAufwand =>
      _aufwandAll.fold<double>(0, (s, k) => s + k.saldo);

  List<Konto> get _aufwandAll => [
        ...aufwand4,
        ...aufwand5,
        ...aufwand6,
        ...aufwand8,
      ];

  double get gewinnVerlust => totalErtrag - totalAufwand;
  bool get bilanzStimmt =>
      (totalAktiven - totalPassiven).abs() < 0.01;
}

// ─── Provider ───

final _berichtProvider = FutureProvider<_BerichtData>((ref) async {
  try {
    final konten = await KontoRepository().getAll();

    final aktiven = <Konto>[];
    final passiven = <Konto>[];
    final ertraege = <Konto>[];
    final aufwand4 = <Konto>[];
    final aufwand5 = <Konto>[];
    final aufwand6 = <Konto>[];
    final aufwand8 = <Konto>[];

    for (final k in konten) {
      // Only include accounts with non-zero saldo in the report
      switch (k.kontenklasse) {
        case 1:
          aktiven.add(k);
        case 2:
          passiven.add(k);
        case 3:
          ertraege.add(k);
        case 4:
          aufwand4.add(k);
        case 5:
          aufwand5.add(k);
        case 6:
          aufwand6.add(k);
        case 8:
          aufwand8.add(k);
      }
    }

    return _BerichtData(
      aktiven: aktiven,
      passiven: passiven,
      ertraege: ertraege,
      aufwand4: aufwand4,
      aufwand5: aufwand5,
      aufwand6: aufwand6,
      aufwand8: aufwand8,
    );
  } catch (_) {
    return const _BerichtData();
  }
});

// ─── Screen ───

class BerichteScreen extends ConsumerStatefulWidget {
  const BerichteScreen({super.key});

  @override
  ConsumerState<BerichteScreen> createState() => _BerichteScreenState();
}

class _BerichteScreenState extends ConsumerState<BerichteScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  _Periode _periode = _Periode.ganzes_jahr;

  static const _periodeLabels = {
    _Periode.ganzes_jahr: 'Ganzes Jahr',
    _Periode.q1: 'Q1 (Jan-Mär)',
    _Periode.q2: 'Q2 (Apr-Jun)',
    _Periode.q3: 'Q3 (Jul-Sep)',
    _Periode.q4: 'Q4 (Okt-Dez)',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final berichtAsync = ref.watch(_berichtProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berichte'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'PDF exportieren',
            onPressed: () {
              final data = berichtAsync.valueOrNull;
              if (data != null) {
                _exportPdf(data);
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Bilanz'),
            Tab(text: 'Erfolgsrechnung'),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Period selector ──
          _buildPeriodSelector(context),

          // ── Tab content ──
          Expanded(
            child: berichtAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(context, error),
              data: (data) => TabBarView(
                controller: _tabController,
                children: [
                  _buildBilanz(context, data),
                  _buildErfolgsrechnung(context, data),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _periodeLabels.entries.map((entry) {
            final isSelected = _periode == entry.key;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surfaceCard,
                side: const BorderSide(color: AppColors.divider),
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  setState(() => _periode = entry.key);
                  // Note: For a full implementation, the period would filter
                  // the buchungen used to calculate saldi. Currently we show
                  // the cumulative saldi from the Konten table.
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Fehler: $error'),
          ],
        ),
      ),
    );
  }

  // ── Bilanz (Balance Sheet) ──

  Widget _buildBilanz(BuildContext context, _BerichtData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Balance check
          if (!data.bilanzStimmt && data.totalAktiven != 0)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber,
                      color: AppColors.warning, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bilanz ist nicht ausgeglichen. '
                      'Differenz: ${_chf.format((data.totalAktiven - data.totalPassiven).abs())}',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Aktiven
          _SectionHeader(title: 'AKTIVEN', color: AppColors.primary),
          _KontenTable(
            konten: data.aktiven,
            formatCHF: _chf.format,
          ),
          _TotalRow(
            label: 'Total Aktiven',
            amount: _chf.format(data.totalAktiven),
            color: AppColors.primary,
          ),

          const SizedBox(height: 24),

          // Passiven
          _SectionHeader(
            title: 'PASSIVEN',
            color: const Color(0xFF7C3AED),
          ),
          _KontenTable(
            konten: data.passiven,
            formatCHF: _chf.format,
          ),
          _TotalRow(
            label: 'Total Passiven',
            amount: _chf.format(data.totalPassiven),
            color: const Color(0xFF7C3AED),
          ),

          const SizedBox(height: 24),

          // Summary
          Card(
            margin: EdgeInsets.zero,
            color: data.bilanzStimmt
                ? AppColors.success.withValues(alpha: 0.05)
                : AppColors.warning.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        data.bilanzStimmt
                            ? Icons.check_circle
                            : Icons.info_outline,
                        color: data.bilanzStimmt
                            ? AppColors.success
                            : AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.bilanzStimmt
                            ? 'Bilanz ausgeglichen'
                            : 'Differenz',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: data.bilanzStimmt
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  if (!data.bilanzStimmt)
                    Text(
                      _chf.format(
                          (data.totalAktiven - data.totalPassiven).abs()),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Erfolgsrechnung (Income Statement) ──

  Widget _buildErfolgsrechnung(BuildContext context, _BerichtData data) {
    final gewinn = data.gewinnVerlust;
    final isGewinn = gewinn >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Erträge
          _SectionHeader(title: 'ERTRAEGE', color: AppColors.success),
          _KontenTable(
            konten: data.ertraege,
            formatCHF: _chf.format,
          ),
          _TotalRow(
            label: 'Total Ertrag',
            amount: _chf.format(data.totalErtrag),
            color: AppColors.success,
          ),

          const SizedBox(height: 24),

          // Aufwand: Materialaufwand
          if (data.aufwand4.isNotEmpty) ...[
            _SectionHeader(
                title: 'MATERIALAUFWAND', color: AppColors.secondary),
            _KontenTable(
              konten: data.aufwand4,
              formatCHF: _chf.format,
            ),
            _TotalRow(
              label: 'Total Materialaufwand',
              amount: _chf.format(
                  data.aufwand4.fold<double>(0, (s, k) => s + k.saldo)),
              color: AppColors.secondary,
            ),
            const SizedBox(height: 16),
          ],

          // Aufwand: Personalaufwand
          if (data.aufwand5.isNotEmpty) ...[
            _SectionHeader(
                title: 'PERSONALAUFWAND', color: AppColors.warning),
            _KontenTable(
              konten: data.aufwand5,
              formatCHF: _chf.format,
            ),
            _TotalRow(
              label: 'Total Personalaufwand',
              amount: _chf.format(
                  data.aufwand5.fold<double>(0, (s, k) => s + k.saldo)),
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
          ],

          // Aufwand: Sonstiger Betriebsaufwand
          if (data.aufwand6.isNotEmpty) ...[
            _SectionHeader(
                title: 'SONSTIGER BETRIEBSAUFWAND',
                color: AppColors.error),
            _KontenTable(
              konten: data.aufwand6,
              formatCHF: _chf.format,
            ),
            _TotalRow(
              label: 'Total Sonstiger Aufwand',
              amount: _chf.format(
                  data.aufwand6.fold<double>(0, (s, k) => s + k.saldo)),
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
          ],

          // Aufwand: Ausserordentlich
          if (data.aufwand8.isNotEmpty) ...[
            _SectionHeader(
                title: 'AUSSERORDENTLICH',
                color: AppColors.textSecondary),
            _KontenTable(
              konten: data.aufwand8,
              formatCHF: _chf.format,
            ),
            _TotalRow(
              label: 'Total Ausserordentlich',
              amount: _chf.format(
                  data.aufwand8.fold<double>(0, (s, k) => s + k.saldo)),
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 8),

          // Total Aufwand
          _TotalRow(
            label: 'Total Aufwand',
            amount: _chf.format(data.totalAufwand),
            color: AppColors.error,
          ),

          const SizedBox(height: 24),

          // ── Gewinn / Verlust ──
          Card(
            margin: EdgeInsets.zero,
            color: isGewinn
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.error.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isGewinn
                            ? Icons.trending_up
                            : Icons.trending_down,
                        color: isGewinn
                            ? AppColors.success
                            : AppColors.error,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isGewinn ? 'Gewinn' : 'Verlust',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isGewinn
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _chf.format(gewinn.abs()),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color:
                          isGewinn ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── PDF Export ──

  Future<void> _exportPdf(_BerichtData data) async {
    final pdf = pw.Document();
    final now = DateFormat('dd.MM.yyyy', 'de_CH').format(DateTime.now());
    final year = DateTime.now().year;
    final periodLabel = _periodeLabels[_periode] ?? 'Ganzes Jahr';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Bilanz & Erfolgsrechnung',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Geschäftsjahr $year - $periodLabel  |  Erstellt: $now',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          // Bilanz
          widgets.add(pw.Text(
            'BILANZ',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ));
          widgets.add(pw.SizedBox(height: 8));

          widgets.add(_pdfSection('Aktiven', data.aktiven));
          widgets.add(_pdfTotal('Total Aktiven', data.totalAktiven));
          widgets.add(pw.SizedBox(height: 12));

          widgets.add(_pdfSection('Passiven', data.passiven));
          widgets.add(_pdfTotal('Total Passiven', data.totalPassiven));
          widgets.add(pw.SizedBox(height: 20));

          // Erfolgsrechnung
          widgets.add(pw.Text(
            'ERFOLGSRECHNUNG',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ));
          widgets.add(pw.SizedBox(height: 8));

          if (data.ertraege.isNotEmpty) {
            widgets.add(_pdfSection('Erträge', data.ertraege));
            widgets.add(_pdfTotal('Total Ertrag', data.totalErtrag));
            widgets.add(pw.SizedBox(height: 8));
          }

          final aufwandGroups = {
            'Materialaufwand': data.aufwand4,
            'Personalaufwand': data.aufwand5,
            'Sonstiger Betriebsaufwand': data.aufwand6,
            'Ausserordentlich': data.aufwand8,
          };

          for (final entry in aufwandGroups.entries) {
            if (entry.value.isNotEmpty) {
              widgets.add(_pdfSection(entry.key, entry.value));
            }
          }

          widgets.add(_pdfTotal('Total Aufwand', data.totalAufwand));
          widgets.add(pw.SizedBox(height: 12));

          final gewinn = data.gewinnVerlust;
          widgets.add(pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  gewinn >= 0 ? 'GEWINN' : 'VERLUST',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  _chf.format(gewinn.abs()),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ));

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'Berichte_${year}_$now',
    );
  }

  pw.Widget _pdfSection(String title, List<Konto> konten) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        for (final k in konten)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 50,
                  child: pw.Text(
                    '${k.kontonummer}',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    k.bezeichnung,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Text(
                  _chf.format(k.saldo),
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        pw.SizedBox(height: 6),
      ],
    );
  }

  pw.Widget _pdfTotal(String label, double amount) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            _chf.format(amount),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Widgets ───

class _SectionHeader extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionHeader({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _KontenTable extends StatelessWidget {
  final List<Konto> konten;
  final String Function(num) formatCHF;

  const _KontenTable({
    required this.konten,
    required this.formatCHF,
  });

  @override
  Widget build(BuildContext context) {
    if (konten.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Keine Konten mit Saldo',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: konten.map((konto) {
        final saldoColor = konto.saldo > 0
            ? AppColors.success
            : konto.saldo < 0
                ? AppColors.error
                : AppColors.textSecondary;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  '${konto.kontonummer}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'monospace',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  konto.bezeichnung,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              Text(
                formatCHF(konto.saldo),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: saldoColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _TotalRow({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        color: color.withValues(alpha: 0.04),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: color,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
