import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/repositories/konto_repository.dart';
import 'package:kmu_tool_app/data/repositories/buchung_repository.dart';

// ─── Providers ───

class _BuchhaltungOverview {
  final double totalAktiven;
  final double totalPassiven;
  final double totalErtrag;
  final double totalAufwand;
  final double offeneDebitoren; // Konto 1100
  final double mwstSchuld; // Konto 2200

  const _BuchhaltungOverview({
    this.totalAktiven = 0,
    this.totalPassiven = 0,
    this.totalErtrag = 0,
    this.totalAufwand = 0,
    this.offeneDebitoren = 0,
    this.mwstSchuld = 0,
  });

  double get gewinnVerlust => totalErtrag - totalAufwand;
}

final _buchhaltungOverviewProvider =
    FutureProvider<_BuchhaltungOverview>((ref) async {
  try {
    final repo = KontoRepository();
    final konten = await repo.getAll();

    double totalAktiven = 0;
    double totalPassiven = 0;
    double totalErtrag = 0;
    double totalAufwand = 0;
    double offeneDebitoren = 0;
    double mwstSchuld = 0;

    for (final konto in konten) {
      switch (konto.kontenklasse) {
        case 1:
          totalAktiven += konto.saldo;
          if (konto.kontonummer == 1100) {
            offeneDebitoren = konto.saldo;
          }
        case 2:
          totalPassiven += konto.saldo;
          if (konto.kontonummer == 2200) {
            mwstSchuld = konto.saldo;
          }
        case 3:
          totalErtrag += konto.saldo;
        case 4:
        case 5:
        case 6:
        case 8:
          totalAufwand += konto.saldo;
      }
    }

    return _BuchhaltungOverview(
      totalAktiven: totalAktiven,
      totalPassiven: totalPassiven,
      totalErtrag: totalErtrag,
      totalAufwand: totalAufwand,
      offeneDebitoren: offeneDebitoren,
      mwstSchuld: mwstSchuld,
    );
  } catch (_) {
    return const _BuchhaltungOverview();
  }
});

// Monthly KPI data for line chart: Aktiven, Passiven, Kontostand (=Eigenkapital)
class _MonthlyKpiData {
  final List<double> aktivenMonthly; // cumulative end-of-month Aktiven
  final List<double> passivenMonthly; // cumulative end-of-month Passiven
  final List<double> kontostandMonthly; // Aktiven - Passiven = Eigenkapital
  final int year;
  final int currentMonth; // 1-based, nur bis hierhin anzeigen

  const _MonthlyKpiData({
    required this.aktivenMonthly,
    required this.passivenMonthly,
    required this.kontostandMonthly,
    required this.year,
    required this.currentMonth,
  });

  double get maxValue {
    double m = 0;
    for (int i = 0; i < currentMonth; i++) {
      m = max(m, aktivenMonthly[i]);
      m = max(m, passivenMonthly[i]);
      m = max(m, kontostandMonthly[i].abs());
    }
    return m;
  }

  double get minValue {
    double m = 0;
    for (int i = 0; i < currentMonth; i++) {
      m = min(m, kontostandMonthly[i]);
    }
    return m;
  }
}

final _monthlyKpiProvider = FutureProvider<_MonthlyKpiData>((ref) async {
  try {
    final now = DateTime.now();
    final year = now.year;
    final currentMonth = now.month;
    final buchungen = await BuchungRepository().getAll();

    // Monthly deltas for Aktiven (Klasse 1) and Passiven (Klasse 2)
    final aktivenDelta = List.filled(12, 0.0);
    final passivenDelta = List.filled(12, 0.0);

    for (final b in buchungen) {
      if (b.datum.year != year) continue;
      final month = b.datum.month - 1; // 0-indexed

      final sollKlasse = b.sollKonto ~/ 1000;
      final habenKlasse = b.habenKonto ~/ 1000;

      // Soll-Seite: Aktiven steigen, Passiven steigen
      if (sollKlasse == 1) aktivenDelta[month] += b.betrag;
      if (sollKlasse == 2) passivenDelta[month] += b.betrag;

      // Haben-Seite: Aktiven sinken, Passiven sinken
      if (habenKlasse == 1) aktivenDelta[month] -= b.betrag;
      if (habenKlasse == 2) passivenDelta[month] -= b.betrag;
    }

    // Kumulative Werte berechnen (inkl. Startsaldo aus Konten)
    // Startsaldo = aktuelle Kontensalden minus laufende Buchungen des Jahres
    final konten = await KontoRepository().getAll();
    double startAktiven = 0;
    double startPassiven = 0;
    for (final k in konten) {
      if (k.kontenklasse == 1) startAktiven += k.saldo;
      if (k.kontenklasse == 2) startPassiven += k.saldo;
    }
    // Aktuelle Salden enthalten alle Buchungen des Jahres → Startsaldo berechnen
    double jahresAktiven = 0;
    double jahresPassiven = 0;
    for (int i = 0; i < 12; i++) {
      jahresAktiven += aktivenDelta[i];
      jahresPassiven += passivenDelta[i];
    }
    startAktiven -= jahresAktiven;
    startPassiven -= jahresPassiven;

    final aktiven = List.filled(12, 0.0);
    final passiven = List.filled(12, 0.0);
    final kontostand = List.filled(12, 0.0);

    double cumAktiven = startAktiven;
    double cumPassiven = startPassiven;
    for (int i = 0; i < 12; i++) {
      cumAktiven += aktivenDelta[i];
      cumPassiven += passivenDelta[i];
      aktiven[i] = cumAktiven;
      passiven[i] = cumPassiven;
      kontostand[i] = cumAktiven - cumPassiven;
    }

    return _MonthlyKpiData(
      aktivenMonthly: aktiven,
      passivenMonthly: passiven,
      kontostandMonthly: kontostand,
      year: year,
      currentMonth: currentMonth,
    );
  } catch (_) {
    return _MonthlyKpiData(
      aktivenMonthly: List.filled(12, 0.0),
      passivenMonthly: List.filled(12, 0.0),
      kontostandMonthly: List.filled(12, 0.0),
      year: DateTime.now().year,
      currentMonth: DateTime.now().month,
    );
  }
});

// ─── Screen ───

class BuchhaltungDashboardScreen extends ConsumerWidget {
  const BuchhaltungDashboardScreen({super.key});

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  static final _chfShort = NumberFormat.currency(
    locale: 'de_CH',
    symbol: '',
    decimalDigits: 0,
  );

  String _formatCHF(double amount) => _chf.format(amount);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(_buchhaltungOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Buchhaltung'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_buchhaltungOverviewProvider);
          ref.invalidate(_monthlyKpiProvider);
          await ref.read(_buchhaltungOverviewProvider.future);
        },
        child: overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError(context, ref, error),
          data: (data) => _buildContent(context, ref, data),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppStatusColors.error),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(_buchhaltungOverviewProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, _BuchhaltungOverview data) {
    final gewinnVerlust = data.gewinnVerlust;
    final isGewinn = gewinnVerlust >= 0;
    final kpiAsync = ref.watch(_monthlyKpiProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── KPI Line Chart ──
        kpiAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (kpi) => _KpiLineChart(
            data: kpi,
            formatAmount: (v) => _chfShort.format(v),
          ),
        ),

        const SizedBox(height: 16),

        // ── Overview Cards ──
        Text(
          'Uebersicht',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),

        // Bilanz-Uebersicht
        _OverviewCard(
          icon: Icons.balance,
          iconColor: Theme.of(context).colorScheme.primary,
          title: 'Bilanz',
          rows: [
            _OverviewRow('Aktiven', _formatCHF(data.totalAktiven)),
            _OverviewRow('Passiven', _formatCHF(data.totalPassiven)),
          ],
        ),
        const SizedBox(height: 8),

        // Erfolgsrechnung
        _OverviewCard(
          icon: Icons.trending_up,
          iconColor: isGewinn ? AppStatusColors.success : AppStatusColors.error,
          title: 'Erfolgsrechnung',
          rows: [
            _OverviewRow('Ertrag', _formatCHF(data.totalErtrag)),
            _OverviewRow('Aufwand', _formatCHF(data.totalAufwand)),
            _OverviewRow(
              isGewinn ? 'Gewinn' : 'Verlust',
              _formatCHF(gewinnVerlust.abs()),
              valueColor: isGewinn ? AppStatusColors.success : AppStatusColors.error,
              isBold: true,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Debitoren & MWST
        Row(
          children: [
            Expanded(
              child: _CompactCard(
                icon: Icons.receipt_long,
                iconColor: Theme.of(context).colorScheme.secondary,
                title: 'Offene Debitoren',
                subtitle: 'Konto 1100',
                value: _formatCHF(data.offeneDebitoren),
                valueColor: data.offeneDebitoren > 0
                    ? AppStatusColors.warning
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _CompactCard(
                icon: Icons.account_balance_wallet,
                iconColor: const Color(0xFF7C3AED),
                title: 'MWST-Schuld',
                subtitle: 'Konto 2200',
                value: _formatCHF(data.mwstSchuld),
                valueColor: data.mwstSchuld > 0
                    ? AppStatusColors.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── Navigation ──
        Text(
          'Bereiche',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),

        _NavigationTile(
          icon: Icons.list_alt,
          iconColor: Theme.of(context).colorScheme.primary,
          title: 'Kontenplan',
          subtitle: 'Schweizer KMU-Kontenrahmen',
          onTap: () => context.push('/buchhaltung/konten'),
        ),
        const SizedBox(height: 8),
        _NavigationTile(
          icon: Icons.menu_book,
          iconColor: AppStatusColors.info,
          title: 'Journal',
          subtitle: 'Alle Buchungen anzeigen',
          onTap: () => context.push('/buchhaltung/buchungen'),
        ),
        const SizedBox(height: 8),
        _NavigationTile(
          icon: Icons.add_circle_outline,
          iconColor: AppStatusColors.success,
          title: 'Neue Buchung',
          subtitle: 'Manuelle Buchung erfassen',
          onTap: () => context.push('/buchhaltung/buchungen/neu'),
        ),
        const SizedBox(height: 8),
        _NavigationTile(
          icon: Icons.account_balance_wallet,
          iconColor: const Color(0xFF7C3AED),
          title: 'MWST-Abrechnung',
          subtitle: 'Effektiv oder Saldosteuersatz',
          onTap: () => context.push('/buchhaltung/mwst'),
        ),
        const SizedBox(height: 8),
        _NavigationTile(
          icon: Icons.assessment,
          iconColor: Theme.of(context).colorScheme.secondary,
          title: 'Berichte',
          subtitle: 'Bilanz & Erfolgsrechnung',
          onTap: () => context.push('/buchhaltung/berichte'),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── KPI Line Chart Widget ───

class _KpiLineChart extends StatelessWidget {
  final _MonthlyKpiData data;
  final String Function(double) formatAmount;

  static const _months = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  static const _colorAktiven = Color(0xFF2563EB); // Blau
  static const _colorPassiven = Color(0xFFEF4444); // Rot
  static const _colorKontostand = Color(0xFF22C55E); // Gruen

  const _KpiLineChart({
    required this.data,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = data.maxValue;
    final minVal = data.minValue;
    final interval = _niceInterval(max(maxVal, minVal.abs()));
    final chartMaxY = interval * ((maxVal / max(interval, 1)).ceil() + 0.5);
    final chartMinY = minVal < 0
        ? -(interval * ((minVal.abs() / max(interval, 1)).ceil() + 0.5))
        : 0.0;

    final spots = data.currentMonth;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.show_chart,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Finanzverlauf ${data.year}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Legend
            Row(
              children: [
                const SizedBox(width: 48),
                _LegendDot(color: _colorAktiven, label: 'Aktiven'),
                const SizedBox(width: 12),
                _LegendDot(color: _colorPassiven, label: 'Passiven'),
                const SizedBox(width: 12),
                _LegendDot(color: _colorKontostand, label: 'Eigenkapital'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (spots - 1).toDouble().clamp(0, 11),
                  minY: chartMinY,
                  maxY: chartMaxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          String label;
                          Color color;
                          switch (spot.barIndex) {
                            case 0:
                              label = 'Aktiven';
                              color = _colorAktiven;
                            case 1:
                              label = 'Passiven';
                              color = _colorPassiven;
                            default:
                              label = 'Eigenkapital';
                              color = _colorKontostand;
                          }
                          return LineTooltipItem(
                            '$label\n${formatAmount(spot.y)} CHF',
                            TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= spots) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _months[idx],
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: max(interval, 1),
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCompact(value),
                            style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: max(interval, 1),
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: value == 0
                          ? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)
                          : Theme.of(context).dividerColor,
                      strokeWidth: value == 0 ? 1 : 0.5,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Aktiven
                    LineChartBarData(
                      spots: List.generate(spots, (i) =>
                          FlSpot(i.toDouble(), data.aktivenMonthly[i])),
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: _colorAktiven,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: _colorAktiven,
                              strokeWidth: 0,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _colorAktiven.withValues(alpha: 0.08),
                      ),
                    ),
                    // Passiven
                    LineChartBarData(
                      spots: List.generate(spots, (i) =>
                          FlSpot(i.toDouble(), data.passivenMonthly[i])),
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: _colorPassiven,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: _colorPassiven,
                              strokeWidth: 0,
                            ),
                      ),
                    ),
                    // Kontostand (Eigenkapital)
                    LineChartBarData(
                      spots: List.generate(spots, (i) =>
                          FlSpot(i.toDouble(), data.kontostandMonthly[i])),
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: _colorKontostand,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3.5,
                              color: _colorKontostand,
                              strokeWidth: 0,
                            ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _colorKontostand.withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _niceInterval(double maxVal) {
    if (maxVal <= 0) return 1000;
    if (maxVal <= 1000) return 500;
    if (maxVal <= 5000) return 1000;
    if (maxVal <= 10000) return 2000;
    if (maxVal <= 50000) return 10000;
    if (maxVal <= 100000) return 20000;
    return 50000;
  }

  static String _formatCompact(double value) {
    if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ─── Helper Widgets ───

class _OverviewRow {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _OverviewRow(this.label, this.value,
      {this.valueColor, this.isBold = false});
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<_OverviewRow> rows;

  const _OverviewCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: TextStyle(
                        color: row.isBold
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight:
                            row.isBold ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      row.value,
                      style: TextStyle(
                        color: row.valueColor ?? Theme.of(context).colorScheme.onSurface,
                        fontWeight:
                            row.isBold ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompactCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String value;
  final Color valueColor;

  const _CompactCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
