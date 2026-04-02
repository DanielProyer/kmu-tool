import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/local/offert_position_local_export.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/data/repositories/offerte_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class OfferteDetailScreen extends ConsumerStatefulWidget {
  final String offerteId;

  const OfferteDetailScreen({super.key, required this.offerteId});

  @override
  ConsumerState<OfferteDetailScreen> createState() =>
      _OfferteDetailScreenState();
}

class _OfferteDetailScreenState
    extends ConsumerState<OfferteDetailScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');
  KundeLocal? _kunde;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadKunde(String kundeId) async {
    if (_kunde != null) return;
    try {
      final kunde = await KundeRepository.getById(kundeId);
      if (kunde != null && mounted) {
        setState(() => _kunde = kunde);
      }
    } catch (_) {}
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'entwurf':
        return AppColors.storniert;
      case 'gesendet':
        return AppColors.offen;
      case 'angenommen':
        return AppColors.abgeschlossen;
      case 'abgelehnt':
        return AppColors.error;
      default:
        return AppColors.storniert;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'entwurf':
        return 'Entwurf';
      case 'gesendet':
        return 'Gesendet';
      case 'angenommen':
        return 'Angenommen';
      case 'abgelehnt':
        return 'Abgelehnt';
      default:
        return status;
    }
  }

  Future<void> _changeStatus(OfferteLocal offerte) async {
    final statuses = ['entwurf', 'gesendet', 'angenommen', 'abgelehnt'];
    final labels = {
      'entwurf': 'Entwurf',
      'gesendet': 'Gesendet',
      'angenommen': 'Angenommen',
      'abgelehnt': 'Abgelehnt',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Status aendern',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
            const Divider(height: 1),
            ...statuses.map((s) => ListTile(
                  leading: Icon(
                    s == offerte.status
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _statusColor(s),
                  ),
                  title: Text(labels[s]!),
                  selected: s == offerte.status,
                  onTap: () => Navigator.pop(ctx, s),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null && selected != offerte.status) {
      offerte.status = selected;
      await OfferteRepository.save(offerte);
      ref.invalidate(offerteProvider(widget.offerteId));
      ref.invalidate(offertenListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Status geaendert zu "${labels[selected]}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final offerteAsync = ref.watch(offerteProvider(widget.offerteId));
    final positionenAsync =
        ref.watch(offertPositionenProvider(widget.offerteId));

    return offerteAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Fehler: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(offerteProvider(widget.offerteId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (offerte) {
        if (offerte == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Offerte nicht gefunden')),
          );
        }

        // Load Kunde info
        _loadKunde(offerte.kundeId);

        return Scaffold(
          appBar: AppBar(
            title: Text(offerte.offertNr ?? 'Offerte'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context.push(
                      '/offerten/${widget.offerteId}/bearbeiten');
                  ref.invalidate(offerteProvider(widget.offerteId));
                  ref.invalidate(
                      offertPositionenProvider(widget.offerteId));
                },
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('PDF-Erstellung kommt in einer zukuenftigen Version'),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ───
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                offerte.offertNr ?? 'Offerte',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700),
                              ),
                            ),
                            _StatusBadge(
                              label:
                                  _statusLabel(offerte.status),
                              color:
                                  _statusColor(offerte.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_kunde != null)
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Kunde',
                            value: _kunde!.firma ??
                                '${_kunde!.vorname ?? ''} ${_kunde!.nachname}'
                                    .trim(),
                          ),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Datum',
                          value: _dateFormat.format(offerte.datum),
                        ),
                        if (offerte.gueltigBis != null)
                          _InfoRow(
                            icon: Icons.event_outlined,
                            label: 'Gueltig bis',
                            value: _dateFormat
                                .format(offerte.gueltigBis!),
                          ),
                        _InfoRow(
                          icon: Icons.percent,
                          label: 'MWST',
                          value:
                              '${offerte.mwstSatz.toStringAsFixed(1)}%',
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Positionen ───
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'POSITIONEN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                positionenAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (positionen) {
                    if (positionen.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Positionen',
                          style: TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Card(
                      child: Column(
                        children: [
                          // Header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                    color: AppColors.divider),
                              ),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                    width: 32,
                                    child: Text('Pos',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors
                                                .textSecondary))),
                                Expanded(
                                    child: Text('Bezeichnung',
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors
                                                .textSecondary))),
                                SizedBox(
                                    width: 80,
                                    child: Text('Betrag',
                                        textAlign:
                                            TextAlign.right,
                                        style: TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 12,
                                            color: AppColors
                                                .textSecondary))),
                              ],
                            ),
                          ),
                          // Rows
                          ...positionen.map((p) => _PositionRow(
                              position: p)),
                        ],
                      ),
                    );
                  },
                ),

                // ─── Totals ───
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _TotalRow(
                          label: 'Netto',
                          value:
                              'CHF ${offerte.totalNetto.toStringAsFixed(2)}',
                        ),
                        _TotalRow(
                          label:
                              'MWST (${offerte.mwstSatz.toStringAsFixed(1)}%)',
                          value:
                              'CHF ${offerte.mwstBetrag.toStringAsFixed(2)}',
                        ),
                        const Divider(),
                        _TotalRow(
                          label: 'Brutto',
                          value:
                              'CHF ${offerte.totalBrutto.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Bemerkung ───
                if (offerte.bemerkung != null &&
                    offerte.bemerkung!.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'BEMERKUNG',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(offerte.bemerkung!),
                    ),
                  ),
                ],

                // ─── Aktionen ───
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _changeStatus(offerte),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Status aendern'),
                      ),
                      const SizedBox(height: 8),
                      if (offerte.status == 'angenommen')
                        FilledButton.icon(
                          onPressed: () async {
                            await context.push(
                                '/auftraege/neu?offerteId=${widget.offerteId}');
                            ref.invalidate(auftraegeListProvider);
                          },
                          icon: const Icon(Icons.assignment_turned_in),
                          label: const Text('Auftrag erstellen'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Helper Widgets ───

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _PositionRow extends StatelessWidget {
  final OffertPositionLocal position;

  const _PositionRow({required this.position});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${position.positionNr}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              Expanded(
                child: Text(
                  position.bezeichnung,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              SizedBox(
                width: 80,
                child: Text(
                  position.betrag.toStringAsFixed(2),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 2),
            child: Text(
              '${position.menge.toStringAsFixed(position.menge == position.menge.roundToDouble() ? 0 : 2)} ${position.einheit ?? 'Stk'} x CHF ${position.einheitspreis.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
