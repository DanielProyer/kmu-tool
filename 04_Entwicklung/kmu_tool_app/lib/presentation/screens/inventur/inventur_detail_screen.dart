import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/inventur_position.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/lager/inventur_service.dart';

class InventurDetailScreen extends ConsumerWidget {
  final String inventurId;

  const InventurDetailScreen({super.key, required this.inventurId});

  Color _statusColor(String status) {
    switch (status) {
      case 'geplant':
        return AppStatusColors.storniert;
      case 'aktiv':
        return AppStatusColors.info;
      case 'abgeschlossen':
        return AppStatusColors.success;
      default:
        return AppStatusColors.storniert;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final inventurAsync = ref.watch(inventurProvider(inventurId));
    final positionenAsync = ref.watch(inventurPositionenProvider(inventurId));

    return inventurAsync.when(
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
                Icon(Icons.error_outline,
                    size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text('Fehler beim Laden: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(inventurProvider(inventurId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (inventur) {
        if (inventur == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Inventur nicht gefunden')),
          );
        }

        final statusColor = _statusColor(inventur.status);
        final gesamt = inventur.positionenGesamt ?? 0;
        final gezaehlt = inventur.positionenGezaehlt ?? 0;
        final dateFormat = DateFormat('dd.MM.yyyy');

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.canPop(context)
                  ? context.pop()
                  : context.go('/inventur'),
            ),
            title: Text(inventur.bezeichnung),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Card ───
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _statusIcon(inventur.status),
                                    size: 14,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    inventur.statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Details
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Stichtag',
                          value: dateFormat.format(inventur.stichtag),
                        ),
                        _DetailRow(
                          icon: Icons.warehouse_outlined,
                          label: 'Lagerort',
                          value: inventur.lagerortBezeichnung ??
                              'Alle Lagerorte',
                        ),

                        // Progress
                        if (gesamt > 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Fortschritt',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '$gezaehlt von $gesamt gezaehlt',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: inventur.fortschritt,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              color: statusColor,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ─── Actions ───
                if (inventur.status == 'geplant') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: FilledButton.icon(
                      onPressed: () async {
                        try {
                          await InventurService.startZaehlung(inventurId);
                          ref.invalidate(inventurProvider(inventurId));
                          if (context.mounted) {
                            context.push('/inventur/$inventurId/zaehlung');
                          }
                        } catch (e) {
                          if (context.mounted) {
                            final msg = e.toString().replaceFirst('Exception: ', '');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: AppStatusColors.error,
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Zaehlung starten'),
                    ),
                  ),
                ],
                if (inventur.status == 'aktiv') ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: FilledButton.icon(
                      onPressed: () async {
                        await context
                            .push('/inventur/$inventurId/zaehlung');
                        ref.invalidate(inventurProvider(inventurId));
                        ref.invalidate(
                            inventurPositionenProvider(inventurId));
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Zaehlung fortsetzen'),
                    ),
                  ),
                  if (gezaehlt == gesamt && gesamt > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _confirmAbschliessen(context, ref),
                        icon: const Icon(Icons.check),
                        label: const Text('Inventur abschliessen'),
                      ),
                    ),
                ],

                // ─── Zusammenfassung (nur bei abgeschlossen) ───
                if (inventur.status == 'abgeschlossen')
                  positionenAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (positionen) {
                      final abweichungen = positionen
                          .where((p) => p.hatAbweichung)
                          .toList();
                      final wertDifferenzGesamt = positionen.fold<double>(
                        0,
                        (sum, p) => sum + p.wertDifferenz,
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'Zusammenfassung'),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _SummaryRow(
                                    label: 'Total Positionen',
                                    value: '$gesamt',
                                  ),
                                  _SummaryRow(
                                    label: 'Abweichungen',
                                    value: '${abweichungen.length}',
                                    valueColor: abweichungen.isNotEmpty
                                        ? AppStatusColors.error
                                        : AppStatusColors.success,
                                  ),
                                  _SummaryRow(
                                    label: 'Wert Abweichungen',
                                    value:
                                        'CHF ${wertDifferenzGesamt.toStringAsFixed(2)}',
                                    valueColor: wertDifferenzGesamt < 0
                                        ? AppStatusColors.error
                                        : wertDifferenzGesamt > 0
                                            ? AppStatusColors.success
                                            : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                // ─── Positionen ───
                const _SectionHeader(title: 'Positionen'),
                positionenAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (positionen) {
                    if (positionen.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Positionen vorhanden',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: positionen.length,
                      itemBuilder: (context, index) {
                        final pos = positionen[index];
                        return _PositionCard(position: pos);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'geplant':
        return Icons.schedule_outlined;
      case 'aktiv':
        return Icons.play_circle_outline;
      case 'abgeschlossen':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _confirmAbschliessen(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inventur abschliessen?'),
        content: const Text(
          'Alle Differenzen werden als Korrekturbewegungen in den '
          'Lagerbestand uebernommen. Diese Aktion kann nicht '
          'rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Abschliessen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final korrekturen =
            await InventurService.abschliessen(inventurId);
        ref.invalidate(inventurProvider(inventurId));
        ref.invalidate(inventurPositionenProvider(inventurId));
        ref.invalidate(inventurenListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                korrekturen > 0
                    ? '$korrekturen Korrekturbewegung${korrekturen == 1 ? '' : 'en'} erstellt'
                    : 'Keine Korrekturen noetig - Bestand stimmt',
              ),
              backgroundColor: AppStatusColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $e'),
              backgroundColor: AppStatusColors.error,
            ),
          );
        }
      }
    }
  }
}

// ─── Section Header ───

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Detail Row ───

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Row ───

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
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
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Position Card ───

class _PositionCard extends StatelessWidget {
  final InventurPosition position;

  const _PositionCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final differenz = position.differenz ?? 0;
    final hatDifferenz = position.hatAbweichung;

    Color? differenzColor;
    if (position.gezaehlt && hatDifferenz) {
      differenzColor =
          differenz < 0 ? AppStatusColors.error : AppStatusColors.success;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Status-Icon
            Icon(
              position.gezaehlt
                  ? Icons.check_circle
                  : Icons.circle_outlined,
              size: 24,
              color: position.gezaehlt
                  ? AppStatusColors.success
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Artikel
                  Text(
                    position.artikelBezeichnung ?? 'Unbekannter Artikel',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 2),

                  // Artikelnummer + Lagerort
                  Row(
                    children: [
                      if (position.artikelArtikelnummer != null &&
                          position.artikelArtikelnummer!.isNotEmpty) ...[
                        Text(
                          position.artikelArtikelnummer!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (position.lagerortBezeichnung != null)
                        Text(
                          position.lagerortBezeichnung!,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Bestandszahlen
                  Row(
                    children: [
                      _BestandChip(
                        label: 'Soll',
                        value: position.sollBestand.toStringAsFixed(
                          position.sollBestand == position.sollBestand.roundToDouble()
                              ? 0
                              : 1,
                        ),
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      _BestandChip(
                        label: 'Ist',
                        value: position.gezaehlt
                            ? (position.istBestand ?? 0).toStringAsFixed(
                                (position.istBestand ?? 0) ==
                                        (position.istBestand ?? 0)
                                            .roundToDouble()
                                    ? 0
                                    : 1,
                              )
                            : '-',
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      if (position.gezaehlt)
                        _BestandChip(
                          label: 'Diff',
                          value:
                              '${differenz > 0 ? '+' : ''}${differenz.toStringAsFixed(differenz == differenz.roundToDouble() ? 0 : 1)}',
                          color: differenzColor ?? colorScheme.onSurfaceVariant,
                          bold: hatDifferenz,
                        ),
                    ],
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

// ─── Bestand Chip ───

class _BestandChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _BestandChip({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
