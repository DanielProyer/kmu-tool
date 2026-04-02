import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class AuftraegeListScreen extends ConsumerStatefulWidget {
  const AuftraegeListScreen({super.key});

  @override
  ConsumerState<AuftraegeListScreen> createState() =>
      _AuftraegeListScreenState();
}

class _AuftraegeListScreenState
    extends ConsumerState<AuftraegeListScreen> {
  String _selectedFilter = 'alle';
  final _dateFormat = DateFormat('dd.MM.yyyy');

  final Map<String, String> _statusLabels = const {
    'alle': 'Alle',
    'offen': 'Offen',
    'in_arbeit': 'In Arbeit',
    'abgeschlossen': 'Abgeschlossen',
    'storniert': 'Storniert',
  };

  List<AuftragLocal> _filterAuftraege(List<AuftragLocal> auftraege) {
    if (_selectedFilter == 'alle') return auftraege;
    return auftraege
        .where((a) => a.status == _selectedFilter)
        .toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'offen':
        return AppColors.offen;
      case 'in_arbeit':
        return AppColors.inBearbeitung;
      case 'abgeschlossen':
        return AppColors.abgeschlossen;
      case 'storniert':
        return AppColors.storniert;
      default:
        return AppColors.storniert;
    }
  }

  String _statusLabel(String status) {
    return _statusLabels[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final auftraegeAsync = ref.watch(auftraegeListProvider);
    final kundenAsync = ref.watch(kundenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Auftraege'),
      ),
      body: Column(
        children: [
          // ─── Filter Chips ───
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _statusLabels.entries.map((entry) {
                final isSelected = _selectedFilter == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = entry.key);
                    },
                    selectedColor: entry.key == 'alle'
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                        : _statusColor(entry.key)
                            .withValues(alpha: 0.2),
                    checkmarkColor: entry.key == 'alle'
                        ? Theme.of(context).colorScheme.primary
                        : _statusColor(entry.key),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? (entry.key == 'alle'
                              ? Theme.of(context).colorScheme.primary
                              : _statusColor(entry.key))
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Liste ───
          Expanded(
            child: auftraegeAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text('Fehler beim Laden: $error'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(auftraegeListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (auftraege) {
                final filtered = _filterAuftraege(auftraege);

                if (auftraege.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 72,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Auftraege erfasst',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Erstelle deinen ersten Auftrag mit dem + Button',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Keine Auftraege mit Status "${_statusLabel(_selectedFilter)}"',
                      style: const TextStyle(
                          color: AppColors.textSecondary),
                    ),
                  );
                }

                // Build Kunden lookup map
                final Map<String, KundeLocal> kundenMap = {};
                kundenAsync.whenData((kunden) {
                  for (final k in kunden) {
                    final key =
                        k.serverId ?? k.id.toString();
                    kundenMap[key] = k;
                  }
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(auftraegeListProvider);
                    ref.invalidate(kundenListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final auftrag = filtered[index];
                      final kunde = kundenMap[auftrag.kundeId];
                      final kundeName = kunde != null
                          ? (kunde.firma ??
                              '${kunde.vorname ?? ''} ${kunde.nachname}'
                                  .trim())
                          : '';

                      return _AuftragCard(
                        auftrag: auftrag,
                        kundeName: kundeName,
                        dateFormat: _dateFormat,
                        statusColor: _statusColor(auftrag.status),
                        statusLabel: _statusLabel(auftrag.status),
                        onTap: () async {
                          await context
                              .push('/auftraege/${auftrag.routeId}');
                          ref.invalidate(auftraegeListProvider);
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
          await context.push('/auftraege/neu');
          ref.invalidate(auftraegeListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Auftrag Card ───

class _AuftragCard extends StatelessWidget {
  final AuftragLocal auftrag;
  final String kundeName;
  final DateFormat dateFormat;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _AuftragCard({
    required this.auftrag,
    required this.kundeName,
    required this.dateFormat,
    required this.statusColor,
    required this.statusLabel,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      auftrag.auftragsNr ?? 'Auftrag',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    label: statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (kundeName.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        kundeName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              if (auftrag.beschreibung != null &&
                  auftrag.beschreibung!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  auftrag.beschreibung!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
              if (auftrag.geplantVon != null ||
                  auftrag.geplantBis != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.date_range_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _buildZeitraumText(),
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
      ),
    );
  }

  String _buildZeitraumText() {
    final von = auftrag.geplantVon != null
        ? dateFormat.format(auftrag.geplantVon!)
        : '–';
    final bis = auftrag.geplantBis != null
        ? dateFormat.format(auftrag.geplantBis!)
        : '–';
    return '$von  –  $bis';
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
