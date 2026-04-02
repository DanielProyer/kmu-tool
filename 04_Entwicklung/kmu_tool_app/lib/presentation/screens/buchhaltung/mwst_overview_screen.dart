import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/mwst_einstellung.dart';
import 'package:kmu_tool_app/data/models/mwst_abrechnung.dart';
import 'package:kmu_tool_app/data/repositories/mwst_repository.dart';
import 'package:kmu_tool_app/services/mwst/mwst_service.dart';

// ─── Providers ───

final _einstellungProvider = FutureProvider<MwstEinstellung?>((ref) async {
  return MwstRepository().getEinstellung();
});

final _abrechnungenProvider =
    FutureProvider<List<MwstAbrechnung>>((ref) async {
  return MwstRepository().getAbrechnungen();
});

// ─── Screen ───

class MwstOverviewScreen extends ConsumerStatefulWidget {
  const MwstOverviewScreen({super.key});

  @override
  ConsumerState<MwstOverviewScreen> createState() =>
      _MwstOverviewScreenState();
}

class _MwstOverviewScreenState extends ConsumerState<MwstOverviewScreen> {
  bool _isGenerating = false;

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  Future<void> _generateAbrechnung() async {
    setState(() => _isGenerating = true);
    try {
      final service = MwstService();
      final periode = await service.getNextPeriode();

      final abrechnung = await service.generateAbrechnung(
        periodeStart: periode.start,
        periodeEnd: periode.end,
      );

      ref.invalidate(_abrechnungenProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'MWST-Abrechnung ${abrechnung.periodeLabel} erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        // Navigate to detail
        context.push('/buchhaltung/mwst/abrechnung/${abrechnung.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final einstellungAsync = ref.watch(_einstellungProvider);
    final abrechnungenAsync = ref.watch(_abrechnungenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MWST-Abrechnung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'MWST-Einstellungen',
            onPressed: () =>
                context.push('/buchhaltung/mwst/einstellungen'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_einstellungProvider);
          ref.invalidate(_abrechnungenProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Einstellungen-Karte ──
            einstellungAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Fehler: $e'),
              data: (einstellung) {
                if (einstellung == null) {
                  return _NoSettingsCard(
                    onSetup: () =>
                        context.push('/buchhaltung/mwst/einstellungen'),
                  );
                }
                return _SettingsCard(einstellung: einstellung);
              },
            ),
            const SizedBox(height: 16),

            // ── Abrechnung erstellen ──
            FilledButton.icon(
              onPressed: _isGenerating ? null : _generateAbrechnung,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.calculate),
              label: const Text('Neue Abrechnung erstellen'),
            ),
            const SizedBox(height: 24),

            // ── Bisherige Abrechnungen ──
            Text(
              'BISHERIGE ABRECHNUNGEN',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            abrechnungenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Fehler: $e'),
              data: (abrechnungen) {
                if (abrechnungen.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          const Text('Noch keine Abrechnungen vorhanden'),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: abrechnungen.map((a) {
                    return _AbrechnungCard(
                      abrechnung: a,
                      chf: _chf,
                      onTap: () => context.push(
                          '/buchhaltung/mwst/abrechnung/${a.id}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSettingsCard extends StatelessWidget {
  final VoidCallback onSetup;

  const _NoSettingsCard({required this.onSetup});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppStatusColors.warning.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.warning_amber, size: 36, color: AppStatusColors.warning),
            const SizedBox(height: 12),
            const Text(
              'MWST noch nicht eingerichtet',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Bitte zuerst die Abrechnungsmethode und den '
              'Saldosteuersatz konfigurieren.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.settings),
              label: const Text('Einrichten'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final MwstEinstellung einstellung;

  const _SettingsCard({required this.einstellung});

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.account_balance_wallet,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    einstellung.methodeLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow('Periode', einstellung.periodeLabel),
            if (einstellung.mwstNummer != null)
              _InfoRow('MWST-Nr.', einstellung.mwstNummer!),
            if (einstellung.isSaldosteuersatz) ...[
              _InfoRow(
                'SSS 1',
                '${einstellung.saldosteuersatz1?.toStringAsFixed(2) ?? "-"}% '
                    '(${einstellung.saldosteuersatz1Bez ?? "-"})',
              ),
              if (einstellung.hatZweitenSss)
                _InfoRow(
                  'SSS 2',
                  '${einstellung.saldosteuersatz2?.toStringAsFixed(2) ?? "-"}% '
                      '(${einstellung.saldosteuersatz2Bez ?? "-"})',
                ),
            ],
            _InfoRow(
              'Entgelt',
              einstellung.vereinbartesEntgelt
                  ? 'Vereinbart (Rechnungsdatum)'
                  : 'Vereinnahmt (Zahlungseingang)',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _AbrechnungCard extends StatelessWidget {
  final MwstAbrechnung abrechnung;
  final NumberFormat chf;
  final VoidCallback onTap;

  const _AbrechnungCard({
    required this.abrechnung,
    required this.chf,
    required this.onTap,
  });

  Color get _statusColor {
    switch (abrechnung.status) {
      case 'entwurf':
        return AppStatusColors.warning;
      case 'eingereicht':
        return AppStatusColors.info;
      case 'bezahlt':
        return AppStatusColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final zahlung = abrechnung.istZahllast
        ? chf.format(abrechnung.ziff500)
        : '-${chf.format(abrechnung.ziff510)}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      abrechnung.periodeLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            abrechnung.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          abrechnung.isEffektiv
                              ? 'Effektiv'
                              : 'SSS',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                zahlung,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: abrechnung.istZahllast
                      ? AppStatusColors.error
                      : AppStatusColors.success,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
