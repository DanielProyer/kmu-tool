import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/rechnung.dart';
import 'package:kmu_tool_app/data/models/kunde.dart';
import 'package:kmu_tool_app/data/repositories/rechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';

/// Providers for the Rechnungen list screen.

final _rechnungenProvider = FutureProvider<List<Rechnung>>((ref) async {
  final repo = RechnungRepository();
  return repo.getAll();
});

final _kundenMapProvider =
    FutureProvider<Map<String, Kunde>>((ref) async {
  final kundenLocal = await KundeRepository.getAll();
  final map = <String, Kunde>{};
  for (final kl in kundenLocal) {
    final id = kl.serverId ?? kl.id.toString();
    map[id] = Kunde(
      id: id,
      userId: kl.userId,
      firma: kl.firma,
      vorname: kl.vorname,
      nachname: kl.nachname ?? '',
      strasse: kl.strasse,
      plz: kl.plz,
      ort: kl.ort,
    );
  }
  return map;
});

class RechnungenListScreen extends ConsumerStatefulWidget {
  const RechnungenListScreen({super.key});

  @override
  ConsumerState<RechnungenListScreen> createState() =>
      _RechnungenListScreenState();
}

class _RechnungenListScreenState extends ConsumerState<RechnungenListScreen> {
  String _filter = 'alle';

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');

  static const _statusFilters = [
    'alle',
    'entwurf',
    'gesendet',
    'bezahlt',
    'gemahnt',
  ];

  static const _statusLabels = {
    'alle': 'Alle',
    'entwurf': 'Entwurf',
    'gesendet': 'Gesendet',
    'bezahlt': 'Bezahlt',
    'gemahnt': 'Gemahnt',
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'entwurf':
        return Colors.grey;
      case 'gesendet':
        return AppColors.info;
      case 'bezahlt':
        return AppColors.success;
      case 'storniert':
        return Colors.grey;
      case 'gemahnt':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'entwurf':
        return 'Entwurf';
      case 'gesendet':
        return 'Gesendet';
      case 'bezahlt':
        return 'Bezahlt';
      case 'storniert':
        return 'Storniert';
      case 'gemahnt':
        return 'Gemahnt';
      default:
        return status;
    }
  }

  bool _isUeberfaellig(Rechnung r) {
    return r.status == 'gesendet' && r.faelligAm.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final rechnungenAsync = ref.watch(_rechnungenProvider);
    final kundenMapAsync = ref.watch(_kundenMapProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Rechnungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: () {
              ref.invalidate(_rechnungenProvider);
              ref.invalidate(_kundenMapProvider);
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
              children: _statusFilters.map((f) {
                final isSelected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_statusLabels[f] ?? f),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Liste ───
          Expanded(
            child: rechnungenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        'Fehler beim Laden: $e',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              data: (rechnungen) {
                // Apply filter
                final filtered = _filter == 'alle'
                    ? rechnungen
                    : rechnungen
                        .where((r) => r.status == _filter)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: AppColors.divider),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'alle'
                              ? 'Noch keine Rechnungen'
                              : 'Keine Rechnungen mit Status "${_statusLabels[_filter]}"',
                          style:
                              const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final kundenMap = kundenMapAsync.valueOrNull ?? {};

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(_rechnungenProvider);
                    ref.invalidate(_kundenMapProvider);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final rechnung = filtered[index];
                      final kunde = kundenMap[rechnung.kundeId];
                      final kundeName =
                          kunde?.displayName ?? 'Unbekannter Kunde';
                      final isUeberfaellig = _isUeberfaellig(rechnung);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isUeberfaellig
                                ? AppColors.error.withValues(alpha: 0.5)
                                : AppColors.divider,
                            width: isUeberfaellig ? 1.5 : 1,
                          ),
                        ),
                        child: InkWell(
                          onTap: () =>
                              context.push('/rechnungen/${rechnung.id}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Rechnungs-Nr + Status
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      rechnung.rechnungsNr,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    _StatusBadge(
                                      label: _statusLabel(rechnung.status),
                                      color: _statusColor(rechnung.status),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Kunde
                                Row(
                                  children: [
                                    const Icon(Icons.person_outlined,
                                        size: 16,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        kundeName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Bottom row: Datum, Fällig, Betrag
                                Row(
                                  children: [
                                    // Datum
                                    Text(
                                      _dateFormat.format(rechnung.datum),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Fällig am
                                    Icon(
                                      Icons.event_outlined,
                                      size: 14,
                                      color: isUeberfaellig
                                          ? AppColors.error
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Fällig: ${_dateFormat.format(rechnung.faelligAm)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: isUeberfaellig
                                                ? AppColors.error
                                                : AppColors.textSecondary,
                                            fontWeight: isUeberfaellig
                                                ? FontWeight.w600
                                                : null,
                                          ),
                                    ),

                                    const Spacer(),

                                    // Total
                                    Text(
                                      _currencyFormat
                                          .format(rechnung.totalBrutto),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ],
                                ),

                                // Überfällig-Warnung
                                if (isUeberfaellig) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.error.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.warning_amber_rounded,
                                            size: 14, color: AppColors.error),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Überfällig',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
