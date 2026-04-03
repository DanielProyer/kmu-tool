import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/lieferant.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class LieferantenListScreen extends ConsumerStatefulWidget {
  const LieferantenListScreen({super.key});

  @override
  ConsumerState<LieferantenListScreen> createState() =>
      _LieferantenListScreenState();
}

class _LieferantenListScreenState
    extends ConsumerState<LieferantenListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Lieferant> _filterLieferanten(List<Lieferant> lieferanten) {
    if (_searchQuery.isEmpty) return lieferanten;
    final query = _searchQuery.toLowerCase();
    return lieferanten.where((l) {
      final firma = l.firma.toLowerCase();
      final kontaktperson = (l.kontaktperson ?? '').toLowerCase();
      return firma.contains(query) || kontaktperson.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lieferantenAsync = ref.watch(lieferantenListProvider);

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
                  hintText: 'Lieferanten suchen...',
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
            : const Text('Lieferanten'),
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
      body: lieferantenAsync.when(
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
                  onPressed: () => ref.invalidate(lieferantenListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (lieferanten) {
          final filtered = _filterLieferanten(lieferanten);

          if (lieferanten.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_shipping_outlined,
                      size: 72,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Lieferanten erfasst',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle deinen ersten Lieferanten mit dem + Button',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filtered.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Ergebnisse fuer "$_searchQuery"',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(lieferantenListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final lieferant = filtered[index];
                return _LieferantCard(
                  lieferant: lieferant,
                  onTap: () async {
                    await context.push('/lieferanten/${lieferant.id}');
                    ref.invalidate(lieferantenListProvider);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/lieferanten/neu');
          ref.invalidate(lieferantenListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LieferantCard extends StatelessWidget {
  final Lieferant lieferant;
  final VoidCallback onTap;

  const _LieferantCard({
    required this.lieferant,
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
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  lieferant.firma.isNotEmpty
                      ? lieferant.firma[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lieferant.firma,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (lieferant.kontaktperson != null &&
                        lieferant.kontaktperson!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        lieferant.kontaktperson!,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (lieferant.ort != null &&
                            lieferant.ort!.isNotEmpty) ...[
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lieferant.ort!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
                        if (lieferant.ort != null &&
                            lieferant.ort!.isNotEmpty &&
                            lieferant.telefon != null &&
                            lieferant.telefon!.isNotEmpty)
                          const SizedBox(width: 12),
                        if (lieferant.telefon != null &&
                            lieferant.telefon!.isNotEmpty) ...[
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lieferant.telefon!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                        ],
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
}
