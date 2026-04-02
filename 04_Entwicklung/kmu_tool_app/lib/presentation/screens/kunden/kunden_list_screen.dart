import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class KundenListScreen extends ConsumerStatefulWidget {
  const KundenListScreen({super.key});

  @override
  ConsumerState<KundenListScreen> createState() => _KundenListScreenState();
}

class _KundenListScreenState extends ConsumerState<KundenListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<KundeLocal> _filterKunden(List<KundeLocal> kunden) {
    if (_searchQuery.isEmpty) return kunden;
    final query = _searchQuery.toLowerCase();
    return kunden.where((k) {
      final name = '${k.vorname ?? ''} ${k.nachname}'.toLowerCase();
      final firma = (k.firma ?? '').toLowerCase();
      final ort = (k.ort ?? '').toLowerCase();
      final telefon = (k.telefon ?? '').toLowerCase();
      final email = (k.email ?? '').toLowerCase();
      return name.contains(query) ||
          firma.contains(query) ||
          ort.contains(query) ||
          telefon.contains(query) ||
          email.contains(query);
    }).toList();
  }

  String _displayName(KundeLocal k) {
    if (k.firma != null && k.firma!.isNotEmpty) return k.firma!;
    return '${k.vorname ?? ''} ${k.nachname}'.trim();
  }

  String _subtitle(KundeLocal k) {
    final parts = <String>[];
    if (k.firma != null && k.firma!.isNotEmpty) {
      final personName = '${k.vorname ?? ''} ${k.nachname}'.trim();
      if (personName.isNotEmpty) parts.add(personName);
    }
    if (k.ort != null && k.ort!.isNotEmpty) parts.add(k.ort!);
    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final kundenAsync = ref.watch(kundenListProvider);

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
                  hintText: 'Kunden suchen...',
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
            : const Text('Kunden'),
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
      body: kundenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(kundenListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (kunden) {
          final filtered = _filterKunden(kunden);

          if (kunden.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 72,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Kunden erfasst',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Erstelle deinen ersten Kunden mit dem + Button',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
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
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Ergebnisse fuer "$_searchQuery"',
                      style:
                          const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(kundenListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final kunde = filtered[index];
                return _KundeCard(
                  kunde: kunde,
                  displayName: _displayName(kunde),
                  subtitle: _subtitle(kunde),
                  onTap: () async {
                    await context.push('/kunden/${kunde.routeId}');
                    ref.invalidate(kundenListProvider);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/kunden/neu');
          ref.invalidate(kundenListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _KundeCard extends StatelessWidget {
  final KundeLocal kunde;
  final String displayName;
  final String subtitle;
  final VoidCallback onTap;

  const _KundeCard({
    required this.kunde,
    required this.displayName,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primary,
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
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (kunde.telefon != null &&
                        kunde.telefon!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            kunde.telefon!,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
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
