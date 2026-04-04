import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/presentation/providers/betriebsverwaltung_provider.dart';

class LohnUebersichtScreen extends ConsumerStatefulWidget {
  const LohnUebersichtScreen({super.key});

  @override
  ConsumerState<LohnUebersichtScreen> createState() =>
      _LohnUebersichtScreenState();
}

class _LohnUebersichtScreenState extends ConsumerState<LohnUebersichtScreen> {
  int _jahr = DateTime.now().year;

  static const _monate = [
    'Januar', 'Februar', 'Maerz', 'April', 'Mai', 'Juni',
    'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final abrechnungenAsync = ref.watch(lohnabrechnungenJahrProvider(_jahr));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lohnabrechnung'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Vorheriges Jahr',
            onPressed: () => setState(() => _jahr--),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                '$_jahr',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Naechstes Jahr',
            onPressed: () => setState(() => _jahr++),
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
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    ref.invalidate(lohnabrechnungenJahrProvider(_jahr)),
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (abrechnungen) {
          // Gruppiere nach Monat
          final countPerMonat = <int, int>{};
          for (final a in abrechnungen) {
            countPerMonat[a.monat] = (countPerMonat[a.monat] ?? 0) + 1;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 12,
            itemBuilder: (context, index) {
              final monat = index + 1;
              final count = countPerMonat[monat] ?? 0;
              final hasData = count > 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasData
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: hasData
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(
                    _monate[index],
                    style: TextStyle(
                      fontWeight: hasData ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: hasData
                      ? Text('$count Abrechnung${count > 1 ? 'en' : ''}')
                      : const Text('Keine Abrechnungen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/betrieb/lohn/$_jahr/$monat'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
