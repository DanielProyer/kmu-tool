import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/mitarbeiter.dart';
import 'package:kmu_tool_app/data/repositories/lohnabrechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/mitarbeiter_repository.dart';
import 'package:kmu_tool_app/data/repositories/sozialversicherung_repository.dart';
import 'package:kmu_tool_app/presentation/providers/betriebsverwaltung_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';
import 'package:kmu_tool_app/services/lohn/lohn_service.dart';

class LohnMonatScreen extends ConsumerStatefulWidget {
  final int jahr;
  final int monat;

  const LohnMonatScreen({super.key, required this.jahr, required this.monat});

  @override
  ConsumerState<LohnMonatScreen> createState() => _LohnMonatScreenState();
}

class _LohnMonatScreenState extends ConsumerState<LohnMonatScreen> {
  bool _isCalculating = false;

  static const _monate = [
    'Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  Future<void> _berechneAlle() async {
    setState(() => _isCalculating = true);
    try {
      final userId = await BetriebService.getDataOwnerId();
      final mitarbeiterListe = await MitarbeiterRepository.getAll();
      final sv = await SozialversicherungRepository.get();

      // Bestehende Abrechnungen laden
      final bestehende = await LohnabrechnungRepository.getForMonat(
          widget.jahr, widget.monat);
      final bestehendeMap = {
        for (final a in bestehende) a.mitarbeiterId: a
      };

      for (final ma in mitarbeiterListe) {
        if (ma.bruttolohnMonat == null || ma.bruttolohnMonat == 0) {
          continue;
        }
        if (ma.austrittsdatum != null &&
            ma.austrittsdatum!.isBefore(
                DateTime(widget.jahr, widget.monat))) {
          continue;
        }

        final existing = bestehendeMap[ma.id];
        // Nicht ueberschreiben wenn schon freigegeben/ausbezahlt
        if (existing != null && existing.status != 'entwurf') continue;

        final abrechnung = LohnService.berechne(
          mitarbeiter: ma,
          sv: sv,
          userId: userId,
          monat: widget.monat,
          jahr: widget.jahr,
          existingId: existing?.id,
          existingStatus: existing?.status ?? 'entwurf',
        );

        await LohnabrechnungRepository.save(abrechnung);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Loehne berechnet'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(lohnabrechnungMonatProvider(
            (jahr: widget.jahr, monat: widget.monat)));
        ref.invalidate(lohnabrechnungenJahrProvider(widget.jahr));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppStatusColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isCalculating = false);
    }
  }

  String _formatCHF(double amount) {
    return 'CHF ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final params = (jahr: widget.jahr, monat: widget.monat);
    final abrechnungenAsync = ref.watch(lohnabrechnungMonatProvider(params));
    final monatsName = _monate[widget.monat - 1];

    return Scaffold(
      appBar: AppBar(
        title: Text('$monatsName ${widget.jahr}'),
        actions: [
          TextButton.icon(
            onPressed: _isCalculating ? null : _berechneAlle,
            icon: _isCalculating
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.calculate_outlined),
            label: const Text('Berechnen'),
          ),
        ],
      ),
      body: abrechnungenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppStatusColors.error),
              const SizedBox(height: 16),
              Text('Fehler: $error'),
            ],
          ),
        ),
        data: (abrechnungen) {
          if (abrechnungen.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 72,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('Keine Abrechnungen',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Druecke "Berechnen" um Loehne fuer alle Mitarbeiter zu erstellen',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isCalculating ? null : _berechneAlle,
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Jetzt berechnen'),
                    ),
                  ],
                ),
              ),
            );
          }

          return FutureBuilder<Map<String, Mitarbeiter>>(
            future: _loadMitarbeiterMap(),
            builder: (context, snapshot) {
              final maMap = snapshot.data ?? {};

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(
                    lohnabrechnungMonatProvider(params)),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: abrechnungen.length,
                  itemBuilder: (context, index) {
                    final a = abrechnungen[index];
                    final ma = maMap[a.mitarbeiterId];
                    final name = ma?.displayName ?? 'Unbekannt';

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await context.push('/betrieb/lohn/detail/${a.id}');
                          ref.invalidate(lohnabrechnungMonatProvider(params));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _StatusBadge(status: a.status),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${(a.pensum * 100).round()}%',
                                          style: TextStyle(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatCHF(a.nettolohn),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    'Brutto: ${_formatCHF(a.bruttolohn)}',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, Mitarbeiter>> _loadMitarbeiterMap() async {
    final list = await MitarbeiterRepository.getAll();
    return {for (final m in list) m.id: m};
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'freigegeben':
        color = AppStatusColors.warning;
        label = 'Freigegeben';
      case 'ausbezahlt':
        color = AppStatusColors.success;
        label = 'Ausbezahlt';
      default:
        color = Theme.of(context).colorScheme.onSurfaceVariant;
        label = 'Entwurf';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
