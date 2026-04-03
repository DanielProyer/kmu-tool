import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/fahrzeug.dart';
import 'package:kmu_tool_app/presentation/providers/fahrzeug_provider.dart';

class FahrzeugeListScreen extends ConsumerWidget {
  const FahrzeugeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final fahrzeugeAsync = ref.watch(fahrzeugeListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/einstellungen'),
        ),
        title: const Text('Fahrzeuge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/einstellungen/fahrzeuge/neu');
              ref.invalidate(fahrzeugeListProvider);
            },
          ),
        ],
      ),
      body: fahrzeugeAsync.when(
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
                  onPressed: () => ref.invalidate(fahrzeugeListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (fahrzeugList) {
          if (fahrzeugList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.directions_car_outlined,
                      size: 72,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Fahrzeuge erfasst',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle dein erstes Fahrzeug mit dem + Button',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fahrzeugeListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: fahrzeugList.length,
              itemBuilder: (context, index) {
                final fahrzeug = fahrzeugList[index];
                return _FahrzeugCard(
                  fahrzeug: fahrzeug,
                  onTap: () async {
                    await context.push(
                        '/einstellungen/fahrzeuge/${fahrzeug.id}/bearbeiten');
                    ref.invalidate(fahrzeugeListProvider);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/einstellungen/fahrzeuge/neu');
          ref.invalidate(fahrzeugeListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FahrzeugCard extends StatelessWidget {
  final Fahrzeug fahrzeug;
  final VoidCallback onTap;

  const _FahrzeugCard({
    required this.fahrzeug,
    required this.onTap,
  });

  /// Checks if a date is within the next 30 days.
  bool _isUpcoming(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final diff = date.difference(now).inDays;
    return diff >= 0 && diff <= 30;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd.MM.yyyy');

    final mfkUpcoming = _isUpcoming(fahrzeug.naechsteMfk);
    final serviceUpcoming = _isUpcoming(fahrzeug.naechsteService);

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
                child: Icon(
                  Icons.directions_car_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fahrzeug.bezeichnung,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (fahrzeug.kennzeichen != null &&
                        fahrzeug.kennzeichen!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        fahrzeug.kennzeichen!,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (fahrzeug.fahrzeugInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        fahrzeug.fahrzeugInfo,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (fahrzeug.naechsteMfk != null ||
                        fahrzeug.naechsteService != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (fahrzeug.naechsteMfk != null)
                            _DateChip(
                              icon: Icons.verified_outlined,
                              label:
                                  'MFK ${dateFormat.format(fahrzeug.naechsteMfk!)}',
                              isWarning: mfkUpcoming,
                            ),
                          if (fahrzeug.naechsteService != null)
                            _DateChip(
                              icon: Icons.build_outlined,
                              label:
                                  'Service ${dateFormat.format(fahrzeug.naechsteService!)}',
                              isWarning: serviceUpcoming,
                            ),
                        ],
                      ),
                    ],
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

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isWarning;

  const _DateChip({
    required this.icon,
    required this.label,
    required this.isWarning,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning
        ? AppStatusColors.warning
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: isWarning ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
