import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/bestellposition.dart';
import 'package:kmu_tool_app/data/repositories/bestellung_repository.dart';
import 'package:kmu_tool_app/data/repositories/bestellposition_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/lager/bestellvorschlag_service.dart';
import 'package:kmu_tool_app/services/lager/lager_service.dart';

class BestellungDetailScreen extends ConsumerWidget {
  final String bestellungId;

  const BestellungDetailScreen({super.key, required this.bestellungId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bestellungAsync = ref.watch(bestellungProvider(bestellungId));
    final positionenAsync = ref.watch(bestellpositionenProvider(bestellungId));
    final dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');
    final currencyFormat =
        NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');

    return bestellungAsync.when(
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
                      ref.invalidate(bestellungProvider(bestellungId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (bestellung) {
        if (bestellung == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Bestellung nicht gefunden')),
          );
        }

        final statusColor = _statusColor(bestellung.status);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.canPop(context)
                  ? context.pop()
                  : context.go('/bestellungen'),
            ),
            title: Text(bestellung.bestellNr),
            actions: [
              // Status transitions
              if (bestellung.status == 'entwurf')
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  tooltip: 'Als bestellt markieren',
                  onPressed: () => _updateStatus(
                      context, ref, bestellungId, 'bestellt'),
                ),
              if (bestellung.status == 'bestellt')
                IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: 'Stornieren',
                  onPressed: () =>
                      _confirmStorno(context, ref, bestellungId),
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _confirmDelete(context, ref, bestellungId);
                  }
                },
                itemBuilder: (context) => [
                  if (bestellung.status == 'entwurf')
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Loeschen',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
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
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              statusColor.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bestellung.bestellNr,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bestellung.lieferantFirma ??
                                    'Unbekannter Lieferant',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _StatusBadge(
                          label: bestellung.statusLabel,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Bestelldaten ───
                const _SectionHeader(title: 'Bestelldaten'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Bestelldatum',
                          value: bestellung.bestellDatum != null
                              ? dateFormat.format(bestellung.bestellDatum!)
                              : '–',
                        ),
                        _DetailRow(
                          icon: Icons.event_outlined,
                          label: 'Erw. Lieferung',
                          value: bestellung.erwartetesLieferdatum != null
                              ? dateFormat
                                  .format(bestellung.erwartetesLieferdatum!)
                              : '–',
                        ),
                        if (bestellung.lieferDatum != null)
                          _DetailRow(
                            icon: Icons.check_circle_outline,
                            label: 'Geliefert am',
                            value:
                                dateFormat.format(bestellung.lieferDatum!),
                          ),
                        _DetailRow(
                          icon: Icons.payments_outlined,
                          label: 'Total',
                          value:
                              currencyFormat.format(bestellung.totalBetrag),
                        ),
                        if (bestellung.bemerkung != null &&
                            bestellung.bemerkung!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.notes_outlined,
                            label: 'Bemerkung',
                            value: bestellung.bemerkung!,
                          ),
                      ],
                    ),
                  ),
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

                    double total = 0;
                    for (final p in positionen) {
                      total += p.gesamtpreis;
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _tableHeader('Artikel'),
                                ),
                                Expanded(
                                  child: _tableHeader('Menge',
                                      align: TextAlign.right),
                                ),
                                Expanded(
                                  child: _tableHeader('Preis',
                                      align: TextAlign.right),
                                ),
                                Expanded(
                                  child: _tableHeader('Total',
                                      align: TextAlign.right),
                                ),
                                Expanded(
                                  child: _tableHeader('Gelief.',
                                      align: TextAlign.right),
                                ),
                              ],
                            ),
                            Divider(color: colorScheme.outlineVariant),
                            // Rows
                            ...positionen.map((p) => Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          p.artikelBezeichnung ??
                                              'Unbekannt',
                                          style:
                                              const TextStyle(fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          p.menge.toStringAsFixed(0),
                                          textAlign: TextAlign.right,
                                          style:
                                              const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          p.einzelpreis
                                              .toStringAsFixed(2),
                                          textAlign: TextAlign.right,
                                          style:
                                              const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          p.gesamtpreis
                                              .toStringAsFixed(2),
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          '${p.gelieferteMenge.toStringAsFixed(0)}/${p.menge.toStringAsFixed(0)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: p.vollstaendigGeliefert
                                                ? AppStatusColors.success
                                                : p.gelieferteMenge > 0
                                                    ? AppStatusColors
                                                        .warning
                                                    : colorScheme
                                                        .onSurfaceVariant,
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                            Divider(color: colorScheme.outlineVariant),
                            // Total
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Total',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: SizedBox()),
                                  const Expanded(child: SizedBox()),
                                  Expanded(
                                    child: Text(
                                      total.toStringAsFixed(2),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // ─── Wareneingang ───
                if (bestellung.status == 'bestellt' ||
                    bestellung.status == 'teilgeliefert')
                  positionenAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (positionen) {
                      final offene = positionen
                          .where((p) => p.offeneMenge > 0)
                          .toList();
                      if (offene.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionHeader(title: 'Wareneingang'),
                          ...offene.map((p) => Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: AppStatusColors
                                            .warning
                                            .withValues(alpha: 0.1),
                                        child: Icon(
                                          Icons.local_shipping_outlined,
                                          size: 18,
                                          color: AppStatusColors.warning,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.artikelBezeichnung ??
                                                  'Unbekannt',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Offen: ${p.offeneMenge.toStringAsFixed(0)} ${p.artikelEinheit ?? 'Stk'}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      FilledButton.tonal(
                                        onPressed: () =>
                                            _showWareneingangDialog(
                                          context,
                                          ref,
                                          p,
                                        ),
                                        style: FilledButton.styleFrom(
                                          minimumSize: Size.zero,
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 8),
                                        ),
                                        child: const Text(
                                            'Lieferung erfassen'),
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
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

  Color _statusColor(String status) {
    switch (status) {
      case 'entwurf':
        return AppStatusColors.storniert;
      case 'bestellt':
        return AppStatusColors.info;
      case 'teilgeliefert':
        return AppStatusColors.warning;
      case 'geliefert':
        return AppStatusColors.success;
      case 'storniert':
        return AppStatusColors.error;
      default:
        return AppStatusColors.storniert;
    }
  }

  Widget _tableHeader(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref,
      String id, String newStatus) async {
    try {
      await BestellungRepository.updateStatus(id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status geaendert: $newStatus'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(bestellungProvider(id));
        ref.invalidate(bestellungenListProvider);
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

  Future<void> _confirmStorno(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bestellung stornieren?'),
        content: const Text(
          'Moechtest du diese Bestellung wirklich stornieren? '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppStatusColors.error,
            ),
            child: const Text('Stornieren'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      _updateStatus(context, ref, id, 'storniert');
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bestellung loeschen?'),
        content: const Text(
          'Moechtest du diese Bestellung wirklich loeschen? '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppStatusColors.error,
            ),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await BestellungRepository.delete(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bestellung geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          ref.invalidate(bestellungenListProvider);
          context.pop();
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

  Future<void> _showWareneingangDialog(
    BuildContext context,
    WidgetRef ref,
    Bestellposition position,
  ) async {
    final mengeController = TextEditingController(
      text: position.offeneMenge.toStringAsFixed(0),
    );
    final lagerortAsync = ref.read(lagerortListProvider);
    String? selectedLagerortId;

    // Get first available lagerort as default
    lagerortAsync.whenData((lagerorte) {
      if (lagerorte.isNotEmpty) {
        selectedLagerortId = lagerorte.first.id;
      }
    });

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                  'Wareneingang: ${position.artikelBezeichnung ?? 'Artikel'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Offene Menge: ${position.offeneMenge.toStringAsFixed(0)} ${position.artikelEinheit ?? 'Stk'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: mengeController,
                    decoration: const InputDecoration(
                      labelText: 'Gelieferte Menge',
                      prefixIcon: Icon(Icons.inventory_outlined),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  lagerortAsync.when(
                    loading: () => const CircularProgressIndicator(
                        strokeWidth: 2),
                    error: (e, _) => Text('Fehler: $e'),
                    data: (lagerorte) {
                      if (lagerorte.isEmpty) {
                        return const Text(
                            'Keine Lagerorte vorhanden. Bitte zuerst einen Lagerort erstellen.');
                      }
                      return DropdownButtonFormField<String>(
                        value: selectedLagerortId,
                        decoration: const InputDecoration(
                          labelText: 'Lagerort',
                          prefixIcon: Icon(Icons.warehouse_outlined),
                        ),
                        items: lagerorte
                            .map((l) => DropdownMenuItem(
                                  value: l.id,
                                  child: Text(l.bezeichnung),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedLagerortId = value;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () {
                    final menge =
                        double.tryParse(mengeController.text.trim());
                    if (menge == null || menge <= 0) return;
                    if (selectedLagerortId == null) return;
                    Navigator.of(ctx).pop({
                      'menge': menge,
                      'lagerortId': selectedLagerortId,
                    });
                  },
                  child: const Text('Erfassen'),
                ),
              ],
            );
          },
        );
      },
    );

    mengeController.dispose();

    if (result != null && context.mounted) {
      try {
        final menge = result['menge'] as double;
        final lagerortId = result['lagerortId'] as String;

        // Neuer gelieferte Menge = bisherige + neue Lieferung
        final neueGelieferteMenge = position.gelieferteMenge + menge;

        await BestellvorschlagService.registerWareneingang(
          bestellungId: bestellungId,
          positionId: position.id,
          gelieferteMenge: neueGelieferteMenge,
          lagerortId: lagerortId,
        );

        await LagerService.wareneingang(
          artikelId: position.artikelId,
          lagerortId: lagerortId,
          menge: menge,
          bemerkung: 'Wareneingang aus Bestellung',
          referenzTyp: 'bestellung',
          referenzId: bestellungId,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${menge.toStringAsFixed(0)} ${position.artikelEinheit ?? 'Stk'} eingebucht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          ref.invalidate(bestellungProvider(bestellungId));
          ref.invalidate(bestellpositionenProvider(bestellungId));
          ref.invalidate(bestellungenListProvider);
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

// ─── Shared Widgets ───

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
