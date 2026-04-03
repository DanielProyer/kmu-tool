import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/bestellung.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class BestellungenListScreen extends ConsumerStatefulWidget {
  const BestellungenListScreen({super.key});

  @override
  ConsumerState<BestellungenListScreen> createState() =>
      _BestellungenListScreenState();
}

class _BestellungenListScreenState
    extends ConsumerState<BestellungenListScreen> {
  String _filter = 'alle';
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');

  List<Bestellung> _filterBestellungen(List<Bestellung> list) {
    if (_filter == 'alle') return list;
    return list.where((b) => b.status == _filter).toList();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bestellungenAsync = ref.watch(bestellungenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Bestellungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Bestellvorschlaege',
            onPressed: () => context.push('/bestellungen/vorschlaege'),
          ),
        ],
      ),
      body: bestellungenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(bestellungenListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (bestellungen) {
          final filtered = _filterBestellungen(bestellungen);

          return Column(
            children: [
              // ─── Filter Chips ───
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Alle',
                      isSelected: _filter == 'alle',
                      onSelected: () => setState(() => _filter = 'alle'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Entwurf',
                      isSelected: _filter == 'entwurf',
                      onSelected: () => setState(() => _filter = 'entwurf'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Bestellt',
                      isSelected: _filter == 'bestellt',
                      onSelected: () => setState(() => _filter = 'bestellt'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Teilgeliefert',
                      isSelected: _filter == 'teilgeliefert',
                      onSelected: () =>
                          setState(() => _filter = 'teilgeliefert'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Geliefert',
                      isSelected: _filter == 'geliefert',
                      onSelected: () =>
                          setState(() => _filter = 'geliefert'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Storniert',
                      isSelected: _filter == 'storniert',
                      onSelected: () =>
                          setState(() => _filter = 'storniert'),
                    ),
                  ],
                ),
              ),

              // ─── Liste ───
              Expanded(
                child: bestellungen.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 72,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Noch keine Bestellungen',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Erstelle deine erste Bestellung mit dem + Button',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Text(
                                'Keine Bestellungen mit diesem Status',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(bestellungenListProvider);
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 88),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final bestellung = filtered[index];
                                return _BestellungCard(
                                  bestellung: bestellung,
                                  statusColor:
                                      _statusColor(bestellung.status),
                                  dateFormat: _dateFormat,
                                  currencyFormat: _currencyFormat,
                                  onTap: () async {
                                    await context.push(
                                        '/bestellungen/${bestellung.id}');
                                    ref.invalidate(bestellungenListProvider);
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/bestellungen/neu');
          ref.invalidate(bestellungenListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Filter Chip ───

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        color:
            isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}

// ─── Bestellung Card ───

class _BestellungCard extends StatelessWidget {
  final Bestellung bestellung;
  final Color statusColor;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;
  final VoidCallback onTap;

  const _BestellungCard({
    required this.bestellung,
    required this.statusColor,
    required this.dateFormat,
    required this.currencyFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Bestell-Nr + Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    bestellung.bestellNr,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  _StatusBadge(
                    label: bestellung.statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Lieferant
              Row(
                children: [
                  Icon(Icons.local_shipping_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bestellung.lieferantFirma ?? 'Unbekannter Lieferant',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bottom row: Datum + Total
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    bestellung.bestellDatum != null
                        ? dateFormat.format(bestellung.bestellDatum!)
                        : '–',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    currencyFormat.format(bestellung.totalBetrag),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ───

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
