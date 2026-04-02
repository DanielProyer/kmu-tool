import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class OffertenListScreen extends ConsumerStatefulWidget {
  const OffertenListScreen({super.key});

  @override
  ConsumerState<OffertenListScreen> createState() =>
      _OffertenListScreenState();
}

class _OffertenListScreenState extends ConsumerState<OffertenListScreen> {
  String _selectedFilter = 'alle';
  final _dateFormat = DateFormat('dd.MM.yyyy');

  final Map<String, String> _statusLabels = const {
    'alle': 'Alle',
    'entwurf': 'Entwurf',
    'gesendet': 'Gesendet',
    'angenommen': 'Angenommen',
    'abgelehnt': 'Abgelehnt',
  };

  List<OfferteLocal> _filterOfferten(List<OfferteLocal> offerten) {
    if (_selectedFilter == 'alle') return offerten;
    return offerten
        .where((o) => o.status == _selectedFilter)
        .toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'entwurf':
        return AppStatusColors.storniert;
      case 'gesendet':
        return AppStatusColors.offen;
      case 'angenommen':
        return AppStatusColors.abgeschlossen;
      case 'abgelehnt':
        return AppStatusColors.error;
      default:
        return AppStatusColors.storniert;
    }
  }

  String _statusLabel(String status) {
    return _statusLabels[status] ?? status;
  }

  @override
  Widget build(BuildContext context) {
    final offertenAsync = ref.watch(offertenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Offerten'),
      ),
      body: Column(
        children: [
          // ─── Filter Chips ───
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    selectedColor:
                        entry.key == 'alle'
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
                          : Theme.of(context).colorScheme.onSurfaceVariant,
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
            child: offertenAsync.when(
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
                      Text('Fehler beim Laden: $error'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(offertenListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (offerten) {
                final filtered = _filterOfferten(offerten);

                if (offerten.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 72,
                            color: Theme.of(context).colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Noch keine Offerten erstellt',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Erstelle deine erste Offerte mit dem + Button',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Keine Offerten mit Status "${_statusLabel(_selectedFilter)}"',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(offertenListProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final offerte = filtered[index];
                      return _OfferteCard(
                        offerte: offerte,
                        dateFormat: _dateFormat,
                        statusColor: _statusColor(offerte.status),
                        statusLabel: _statusLabel(offerte.status),
                        onTap: () async {
                          await context
                              .push('/offerten/${offerte.routeId}');
                          ref.invalidate(offertenListProvider);
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
          await context.push('/offerten/neu');
          ref.invalidate(offertenListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _OfferteCard extends StatefulWidget {
  final OfferteLocal offerte;
  final DateFormat dateFormat;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  const _OfferteCard({
    required this.offerte,
    required this.dateFormat,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  @override
  State<_OfferteCard> createState() => _OfferteCardState();
}

class _OfferteCardState extends State<_OfferteCard> {
  String _kundeName = '';

  @override
  void initState() {
    super.initState();
    _loadKundeName();
  }

  Future<void> _loadKundeName() async {
    try {
      final kunde =
          await KundeRepository.getById(widget.offerte.kundeId);
      if (kunde != null && mounted) {
        setState(() {
          _kundeName = kunde.firma ?? '${kunde.vorname ?? ''} ${kunde.nachname}'.trim();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: widget.onTap,
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
                      widget.offerte.offertNr ?? 'Offerte',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  _StatusBadge(
                    label: widget.statusLabel,
                    color: widget.statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_kundeName.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _kundeName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    widget.dateFormat.format(widget.offerte.datum),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'CHF ${widget.offerte.totalBrutto.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
