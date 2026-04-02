import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/konto.dart';
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

// Monthly Ertrag/Aufwand data for chart
class _MonthlyData {
  final List<double> ertragMonthly; // index 0=Jan, 11=Dec
  final List<double> aufwandMonthly;
  final int year;

  const _MonthlyData({
    required this.ertragMonthly,
    required this.aufwandMonthly,
    required this.year,
  });

  double get maxValue {
    double m = 0;
    for (int i = 0; i < 12; i++) {
      m = max(m, ertragMonthly[i]);
      m = max(m, aufwandMonthly[i]);
    }
    return m;
  }

  bool get hasData => ertragMonthly.any((v) => v > 0) ||
      aufwandMonthly.any((v) => v > 0);
}

final _monthlyDataProvider = FutureProvider<_MonthlyData>((ref) async {
  try {
    final year = DateTime.now().year;
    final buchungen = await BuchungRepository().getAll();

    final ertrag = List.filled(12, 0.0);
    final aufwand = List.filled(12, 0.0);

    for (final b in buchungen) {
      if (b.datum.year != year) continue;
      final month = b.datum.month - 1; // 0-indexed

      // Ertrag: Haben-Konto in Kontenklasse 3 (3000-3999)
      final habenKlasse = b.habenKonto ~/ 1000;
      if (habenKlasse == 3) {
        ertrag[month] += b.betrag;
      }

      // Aufwand: Soll-Konto in Kontenklasse 4-8
      final sollKlasse = b.sollKonto ~/ 1000;
      if (sollKlasse >= 4 && sollKlasse <= 8) {
        aufwand[month] += b.betrag;
      }
    }

    return _MonthlyData(
      ertragMonthly: ertrag,
      aufwandMonthly: aufwand,
      year: year,
    );
  } catch (_) {
    return _MonthlyData(
      ertragMonthly: List.filled(12, 0.0),
      aufwandMonthly: List.filled(12, 0.0),
      year: DateTime.now().year,
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
        title: const Text('Buchhaltung'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_buchhaltungOverviewProvider);
          ref.invalidate(_monthlyDataProvider);
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
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
    final monthlyAsync = ref.watch(_monthlyDataProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Overview Cards ──
        Text(
          'Uebersicht',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),

        // Bilanz-Uebersicht
        _OverviewCard(
          icon: Icons.balance,
          iconColor: AppColors.primary,
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
          iconColor: isGewinn ? AppColors.success : AppColors.error,
          title: 'Erfolgsrechnung',
          rows: [
            _OverviewRow('Ertrag', _formatCHF(data.totalErtrag)),
            _OverviewRow('Aufwand', _formatCHF(data.totalAufwand)),
            _OverviewRow(
              isGewinn ? 'Gewinn' : 'Verlust',
              _formatCHF(gewinnVerlust.abs()),
              valueColor: isGewinn ? AppColors.success : AppColors.error,
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
                iconColor: AppColors.secondary,
                title: 'Offene Debitoren',
                subtitle: 'Konto 1100',
                value: _formatCHF(data.offeneDebitoren),
                valueColor: data.offeneDebitoren > 0
                    ? AppColors.warning
                    : AppColors.textSecondary,
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
                    ? AppColors.error
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── Monthly Chart ──
        monthlyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (monthly) {
            if (!monthly.hasData) return const SizedBox.shrink();
            return _MonthlyChart(
              data: monthly,
              formatAmount: (v) => _chfShort.format(v),
            );
          },
        ),

        const SizedBox(height: 28),

        // ── Navigation ──
        Text(
          'Bereiche',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 12),

        _NavigationTile(
          icon: Icons.list_alt,
          iconColor: AppColors.primary,
          title: 'Kontenplan',
          subtitle: 'Schweizer KMU-Kontenrahmen',
          onTap: () => context.push('/buchhaltung/konten'),
        ),
        const SizedBox(height: 8),
        _NavigationTile(
          icon: Icons.menu_book,
          iconColor: AppColors.info,
          title: 'Journal',
          subtitle: 'Alle Buchungen anzeigen',
          onTap: () => context.push('/buchhaltung/buchungen'),
        ),
        const SizedBox(height: 8),
        _NavigationTile(
          icon: Icons.add_circle_outline,
          iconColor: AppColors.success,
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
          iconColor: AppColors.secondary,
          title: 'Berichte',
          subtitle: 'Bilanz & Erfolgsrechnung',
          onTap: () => context.push('/buchhaltung/berichte'),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

// ─── Monthly Chart Widget ───

class _MonthlyChart extends StatelessWidget {
  final _MonthlyData data;
  final String Function(double) formatAmount;

  static const _months = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  const _MonthlyChart({
    required this.data,
    required this.formatAmount,
  });

  @override
  Widget build(BuildContext context) {
    final maxVal = data.maxValue;
    if (maxVal == 0) return const SizedBox.shrink();

    // Round up to nice interval
    final interval = _niceInterval(maxVal);

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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.bar_chart,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Ertrag / Aufwand ${data.year}',
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
                _LegendDot(color: AppColors.success, label: 'Ertrag'),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.error, label: 'Aufwand'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: interval * ((maxVal / interval).ceil()).toDouble(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final label = rodIndex == 0 ? 'Ertrag' : 'Aufwand';
                        return BarTooltipItem(
                          '$label\n${formatAmount(rod.toY)} CHF',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
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
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= 12) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            _months[idx],
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 44,
                        interval: interval,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) return const SizedBox.shrink();
                          return Text(
                            _formatCompact(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppColors.divider,
                      strokeWidth: 0.5,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(12, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: data.ertragMonthly[i],
                          color: AppColors.success,
                          width: 6,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                        BarChartRodData(
                          toY: data.aufwandMonthly[i],
                          color: AppColors.error,
                          width: 6,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _niceInterval(double maxVal) {
    if (maxVal <= 1000) return 500;
    if (maxVal <= 5000) return 1000;
    if (maxVal <= 10000) return 2000;
    if (maxVal <= 50000) return 10000;
    if (maxVal <= 100000) return 20000;
    return 50000;
  }

  static String _formatCompact(double value) {
    if (value >= 1000) {
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
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
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
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            row.isBold ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      row.value,
                      style: TextStyle(
                        color: row.valueColor ?? AppColors.textPrimary,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
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
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
