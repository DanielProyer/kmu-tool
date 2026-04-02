import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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

// ─── Screen ───

class BuchhaltungDashboardScreen extends ConsumerWidget {
  const BuchhaltungDashboardScreen({super.key});

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
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
          await ref.read(_buchhaltungOverviewProvider.future);
        },
        child: overviewAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError(context, ref, error),
          data: (data) => _buildContent(context, data),
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

  Widget _buildContent(BuildContext context, _BuchhaltungOverview data) {
    final gewinnVerlust = data.gewinnVerlust;
    final isGewinn = gewinnVerlust >= 0;

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

// ─── Helper Widgets ───

class _OverviewRow {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _OverviewRow(this.label, this.value, {this.valueColor, this.isBold = false});
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
