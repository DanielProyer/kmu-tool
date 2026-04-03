import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/admin/admin_kundenprofil.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';
import 'package:intl/intl.dart';

class AdminKundenListScreen extends ConsumerStatefulWidget {
  const AdminKundenListScreen({super.key});

  @override
  ConsumerState<AdminKundenListScreen> createState() =>
      _AdminKundenListScreenState();
}

class _AdminKundenListScreenState
    extends ConsumerState<AdminKundenListScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'alle';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdminKundenprofil> _filterKunden(List<AdminKundenprofil> kunden) {
    var filtered = kunden;

    // Status filter
    if (_statusFilter != 'alle') {
      filtered = filtered.where((k) => k.status == _statusFilter).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((k) {
        final firma = k.firmaName.toLowerCase();
        final kontakt = (k.kontaktperson ?? '').toLowerCase();
        final email = (k.email ?? '').toLowerCase();
        return firma.contains(query) ||
            kontakt.contains(query) ||
            email.contains(query);
      }).toList();
    }

    return filtered;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'aktiv':
        return AppStatusColors.success;
      case 'inaktiv':
        return AppStatusColors.warning;
      case 'gesperrt':
        return AppStatusColors.error;
      case 'test':
        return AppStatusColors.info;
      default:
        return AppStatusColors.storniert;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kundenAsync = ref.watch(adminKundenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/admin'),
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
      body: Column(
        children: [
          // ─── Filter Chips ───
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Alle',
                  selected: _statusFilter == 'alle',
                  onSelected: () =>
                      setState(() => _statusFilter = 'alle'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Aktiv',
                  selected: _statusFilter == 'aktiv',
                  color: AppStatusColors.success,
                  onSelected: () =>
                      setState(() => _statusFilter = 'aktiv'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inaktiv',
                  selected: _statusFilter == 'inaktiv',
                  color: AppStatusColors.warning,
                  onSelected: () =>
                      setState(() => _statusFilter = 'inaktiv'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Gesperrt',
                  selected: _statusFilter == 'gesperrt',
                  color: AppStatusColors.error,
                  onSelected: () =>
                      setState(() => _statusFilter = 'gesperrt'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Test',
                  selected: _statusFilter == 'test',
                  color: AppStatusColors.info,
                  onSelected: () =>
                      setState(() => _statusFilter = 'test'),
                ),
              ],
            ),
          ),

          // ─── Liste ───
          Expanded(
            child: kundenAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
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
                        style:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(adminKundenListProvider),
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
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Kunden vorhanden',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erstelle den ersten Kunden mit dem + Button',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
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
                            _searchQuery.isNotEmpty
                                ? 'Keine Ergebnisse fuer "$_searchQuery"'
                                : 'Keine Kunden mit diesem Status',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminKundenListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final kunde = filtered[index];
                      return _AdminKundeCard(
                        kunde: kunde,
                        statusColor: _statusColor(kunde.status),
                        onTap: () async {
                          await context
                              .push('/admin/kunden/${kunde.id}');
                          ref.invalidate(adminKundenListProvider);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/kunden/neu');
          ref.invalidate(adminKundenListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Filter Chip ───

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chipColor = color ?? colorScheme.primary;

    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: selected ? chipColor : colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? chipColor : colorScheme.outline,
      ),
    );
  }
}

// ─── Kunde Card ───

class _AdminKundeCard extends StatelessWidget {
  final AdminKundenprofil kunde;
  final Color statusColor;
  final VoidCallback onTap;

  const _AdminKundeCard({
    required this.kunde,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    colorScheme.primary.withValues(alpha: 0.1),
                child: Text(
                  kunde.firmaName.isNotEmpty
                      ? kunde.firmaName[0].toUpperCase()
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
                      kunde.firmaName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (kunde.kontaktperson != null &&
                            kunde.kontaktperson!.isNotEmpty)
                          kunde.kontaktperson!,
                        if (kunde.email != null &&
                            kunde.email!.isNotEmpty)
                          kunde.email!,
                      ].join(' - '),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _StatusBadge(
                          label: kunde.statusLabel,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        if (kunde.planBezeichnung != null)
                          _PlanBadge(label: kunde.planBezeichnung!),
                        const Spacer(),
                        if (kunde.registriertAm != null)
                          Text(
                            dateFormat.format(kunde.registriertAm!),
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
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

// ─── Status Badge ───

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Plan Badge ───

class _PlanBadge extends StatelessWidget {
  final String label;

  const _PlanBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
