import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/bestellvorschlag.dart';
import 'package:kmu_tool_app/data/repositories/bestellvorschlag_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/lager/bestellvorschlag_service.dart';

class BestellvorschlaegeScreen extends ConsumerStatefulWidget {
  const BestellvorschlaegeScreen({super.key});

  @override
  ConsumerState<BestellvorschlaegeScreen> createState() =>
      _BestellvorschlaegeScreenState();
}

class _BestellvorschlaegeScreenState
    extends ConsumerState<BestellvorschlaegeScreen> {
  String _filter = 'alle';
  final Set<String> _selected = {};
  bool _isGenerating = false;
  bool _isCreating = false;

  List<Bestellvorschlag> _filterVorschlaege(List<Bestellvorschlag> list) {
    if (_filter == 'alle') return list;
    return list.where((v) => v.status == _filter).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'offen':
        return AppStatusColors.info;
      case 'bestellt':
        return AppStatusColors.success;
      case 'ignoriert':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }

  Future<void> _generateVorschlaege() async {
    setState(() => _isGenerating = true);
    try {
      final count = await BestellvorschlagService.generateVorschlaege();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? '$count Vorschlaege generiert'
                : 'Keine neuen Vorschlaege noetig'),
            backgroundColor:
                count > 0 ? AppStatusColors.success : AppStatusColors.info,
          ),
        );
        ref.invalidate(bestellvorschlaegeListProvider);
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

  Future<void> _createBestellungFromSelected(
      List<Bestellvorschlag> allVorschlaege) async {
    final selectedVorschlaege =
        allVorschlaege.where((v) => _selected.contains(v.id)).toList();

    if (selectedVorschlaege.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte mindestens einen Vorschlag auswaehlen'),
          backgroundColor: AppStatusColors.warning,
        ),
      );
      return;
    }

    // Prüfen ob alle den gleichen Lieferanten haben
    final lieferantIds = selectedVorschlaege
        .map((v) => v.lieferantId)
        .where((id) => id != null)
        .toSet();

    if (lieferantIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Bitte nur Vorschlaege desselben Lieferanten auswaehlen'),
          backgroundColor: AppStatusColors.warning,
        ),
      );
      return;
    }

    if (lieferantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Kein Lieferant zugewiesen. Bitte zuerst Hauptlieferant hinterlegen.'),
          backgroundColor: AppStatusColors.warning,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    try {
      final bestellungId = await BestellvorschlagService
          .createBestellungFromVorschlaege(selectedVorschlaege);
      if (mounted && bestellungId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bestellung erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        _selected.clear();
        ref.invalidate(bestellvorschlaegeListProvider);
        ref.invalidate(bestellungenListProvider);
        context.push('/bestellungen/$bestellungId');
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
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _ignoreVorschlag(String id) async {
    try {
      await BestellvorschlagRepository.updateStatus(id, 'ignoriert');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Vorschlag ignoriert'),
            backgroundColor: AppStatusColors.storniert,
          ),
        );
        _selected.remove(id);
        ref.invalidate(bestellvorschlaegeListProvider);
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vorschlaegeAsync = ref.watch(bestellvorschlaegeListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/bestellungen'),
        ),
        title: const Text('Bestellvorschlaege'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: () => ref.invalidate(bestellvorschlaegeListProvider),
          ),
        ],
      ),
      body: vorschlaegeAsync.when(
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
                  onPressed: () =>
                      ref.invalidate(bestellvorschlaegeListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (vorschlaege) {
          final filtered = _filterVorschlaege(vorschlaege);

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
                      label: 'Offen',
                      isSelected: _filter == 'offen',
                      onSelected: () => setState(() => _filter = 'offen'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Bestellt',
                      isSelected: _filter == 'bestellt',
                      onSelected: () => setState(() => _filter = 'bestellt'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Ignoriert',
                      isSelected: _filter == 'ignoriert',
                      onSelected: () => setState(() => _filter = 'ignoriert'),
                    ),
                  ],
                ),
              ),

              // ─── Action Bar (visible when items selected) ───
              if (_selected.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  child: Row(
                    children: [
                      Text(
                        '${_selected.length} ausgewaehlt',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: _isCreating
                            ? null
                            : () =>
                                _createBestellungFromSelected(vorschlaege),
                        icon: _isCreating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.shopping_cart_outlined,
                                size: 18),
                        label: const Text('In Bestellung'),
                        style: FilledButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),

              // ─── Liste ───
              Expanded(
                child: vorschlaege.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 72,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Keine Bestellvorschlaege',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Generiere Vorschlaege mit dem Button unten',
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
                                'Keine Vorschlaege mit diesem Status',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(bestellvorschlaegeListProvider);
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 88),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final vorschlag = filtered[index];
                                final isLow = vorschlag.aktuellerBestand <
                                    vorschlag.mindestbestand;
                                final isSelected =
                                    _selected.contains(vorschlag.id);

                                return _VorschlagCard(
                                  vorschlag: vorschlag,
                                  isLow: isLow,
                                  isSelected: isSelected,
                                  statusColor: _statusColor(vorschlag.status),
                                  onTap: vorschlag.status == 'offen'
                                      ? () {
                                          setState(() {
                                            if (isSelected) {
                                              _selected.remove(vorschlag.id);
                                            } else {
                                              _selected.add(vorschlag.id);
                                            }
                                          });
                                        }
                                      : null,
                                  onIgnore: vorschlag.status == 'offen'
                                      ? () => _ignoreVorschlag(vorschlag.id)
                                      : null,
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generateVorschlaege,
        icon: _isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.auto_awesome),
        label: Text(_isGenerating ? 'Generiere...' : 'Vorschlaege generieren'),
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

// ─── Vorschlag Card ───

class _VorschlagCard extends StatelessWidget {
  final Bestellvorschlag vorschlag;
  final bool isLow;
  final bool isSelected;
  final Color statusColor;
  final VoidCallback? onTap;
  final VoidCallback? onIgnore;

  const _VorschlagCard({
    required this.vorschlag,
    required this.isLow,
    required this.isSelected,
    required this.statusColor,
    this.onTap,
    this.onIgnore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : isLow
                  ? AppStatusColors.error.withValues(alpha: 0.4)
                  : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Bezeichnung + Status Badge
              Row(
                children: [
                  if (vorschlag.status == 'offen')
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 22,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      vorschlag.artikelBezeichnung ?? 'Unbekannter Artikel',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(
                    label: vorschlag.statusLabel,
                    color: statusColor,
                  ),
                ],
              ),

              // Artikel-Nr
              if (vorschlag.artikelArtikelnummer != null &&
                  vorschlag.artikelArtikelnummer!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  vorschlag.artikelArtikelnummer!,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Bestand info
              Row(
                children: [
                  Icon(
                    Icons.inventory_outlined,
                    size: 14,
                    color: isLow
                        ? AppStatusColors.error
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bestand: ${vorschlag.aktuellerBestand.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isLow
                          ? AppStatusColors.error
                          : colorScheme.onSurfaceVariant,
                      fontWeight: isLow ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ Min: ${vorschlag.mindestbestand.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.add_shopping_cart,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Menge: ${vorschlag.vorgeschlageneMenge.toStringAsFixed(0)} ${vorschlag.artikelEinheit ?? 'Stk'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Lieferant + Actions
              Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      vorschlag.lieferantFirma ?? 'Kein Lieferant',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onIgnore != null)
                    TextButton.icon(
                      onPressed: onIgnore,
                      icon: const Icon(Icons.visibility_off_outlined,
                          size: 16),
                      label: const Text('Ignorieren'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: colorScheme.onSurfaceVariant,
                        textStyle: const TextStyle(fontSize: 12),
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
