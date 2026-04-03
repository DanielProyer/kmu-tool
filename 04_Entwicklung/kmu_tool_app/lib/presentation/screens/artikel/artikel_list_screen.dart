import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/data/local/artikel_local_export.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class ArtikelListScreen extends ConsumerStatefulWidget {
  const ArtikelListScreen({super.key});

  @override
  ConsumerState<ArtikelListScreen> createState() => _ArtikelListScreenState();
}

class _ArtikelListScreenState extends ConsumerState<ArtikelListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedKategorie = 'alle';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ArtikelLocal> _filterArtikel(List<ArtikelLocal> artikel) {
    var filtered = artikel;

    // Kategorie-Filter
    if (_selectedKategorie != 'alle') {
      filtered =
          filtered.where((a) => a.kategorie == _selectedKategorie).toList();
    }

    // Suchfilter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        final bezeichnung = a.bezeichnung.toLowerCase();
        final artikelNr = (a.artikelNr ?? '').toLowerCase();
        final lieferant = (a.lieferant ?? '').toLowerCase();
        final notizen = (a.notizen ?? '').toLowerCase();
        return bezeichnung.contains(query) ||
            artikelNr.contains(query) ||
            lieferant.contains(query) ||
            notizen.contains(query);
      }).toList();
    }

    return filtered;
  }

  String _kategorieLabel(String kategorie) {
    switch (kategorie) {
      case 'material':
        return 'Material';
      case 'werkzeug':
        return 'Werkzeug';
      case 'verbrauch':
        return 'Verbrauchsmaterial';
      default:
        return kategorie;
    }
  }

  Color _kategorieColor(String kategorie) {
    switch (kategorie) {
      case 'material':
        return AppStatusColors.info;
      case 'werkzeug':
        return AppStatusColors.warning;
      case 'verbrauch':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final artikelAsync = ref.watch(artikelListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Artikel suchen...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
                style: const TextStyle(fontSize: 18),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              )
            : const Text('Artikelstamm'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: artikelAsync.when(
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
                  onPressed: () => ref.invalidate(artikelListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (artikel) {
          final filtered = _filterArtikel(artikel);

          if (artikel.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 72,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Artikel erfasst',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle deinen ersten Artikel mit dem + Button',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

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
                      isSelected: _selectedKategorie == 'alle',
                      onSelected: () =>
                          setState(() => _selectedKategorie = 'alle'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Material',
                      isSelected: _selectedKategorie == 'material',
                      onSelected: () =>
                          setState(() => _selectedKategorie = 'material'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Werkzeug',
                      isSelected: _selectedKategorie == 'werkzeug',
                      onSelected: () =>
                          setState(() => _selectedKategorie = 'werkzeug'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Verbrauchsmaterial',
                      isSelected: _selectedKategorie == 'verbrauch',
                      onSelected: () =>
                          setState(() => _selectedKategorie = 'verbrauch'),
                    ),
                  ],
                ),
              ),

              // ─── Liste ───
              Expanded(
                child: filtered.isEmpty && _searchQuery.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 48,
                                color: colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Keine Ergebnisse fuer "$_searchQuery"',
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
                                'Keine Artikel in dieser Kategorie',
                                style: TextStyle(
                                    color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(artikelListProvider);
                            },
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 88),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final artikel = filtered[index];
                                return _ArtikelCard(
                                  artikel: artikel,
                                  kategorieLabel:
                                      _kategorieLabel(artikel.kategorie),
                                  kategorieColor:
                                      _kategorieColor(artikel.kategorie),
                                  onTap: () async {
                                    await context
                                        .push('/artikel/${artikel.routeId}');
                                    ref.invalidate(artikelListProvider);
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
          await context.push('/artikel/neu');
          ref.invalidate(artikelListProvider);
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
        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}

// ─── Artikel Card ───

class _ArtikelCard extends StatelessWidget {
  final ArtikelLocal artikel;
  final String kategorieLabel;
  final Color kategorieColor;
  final VoidCallback onTap;

  const _ArtikelCard({
    required this.artikel,
    required this.kategorieLabel,
    required this.kategorieColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLowStock = artikel.mindestbestand != null &&
        artikel.lagerbestand < artikel.mindestbestand!;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: kategorieColor.withValues(alpha: 0.1),
                child: Icon(
                  _kategorieIcon(artikel.kategorie),
                  color: kategorieColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bezeichnung + Kategorie-Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            artikel.bezeichnung,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kategorieColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            kategorieLabel,
                            style: TextStyle(
                              color: kategorieColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Artikel-Nr
                    if (artikel.artikelNr != null &&
                        artikel.artikelNr!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        artikel.artikelNr!,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Preis + Lagerbestand
                    Row(
                      children: [
                        Icon(
                          Icons.sell_outlined,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CHF ${artikel.verkaufspreis.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.inventory_outlined,
                          size: 14,
                          color: isLowStock
                              ? AppStatusColors.error
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${artikel.lagerbestand.toStringAsFixed(0)} ${artikel.einheit ?? 'Stk'}',
                          style: TextStyle(
                            color: isLowStock
                                ? AppStatusColors.error
                                : colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: isLowStock
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _kategorieIcon(String kategorie) {
    switch (kategorie) {
      case 'material':
        return Icons.category_outlined;
      case 'werkzeug':
        return Icons.build_outlined;
      case 'verbrauch':
        return Icons.local_drink_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}
