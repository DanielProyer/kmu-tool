import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/presentation/providers/mitarbeiter_provider.dart';

class BerechtigungenScreen extends ConsumerWidget {
  const BerechtigungenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final mitarbeiterAsync = ref.watch(mitarbeiterListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berechtigungen'),
      ),
      body: mitarbeiterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text('Fehler', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(mitarbeiterListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (mitarbeiterList) {
          // Nur Nicht-GF anzeigen (GF hat immer alle Rechte)
          final filtered = mitarbeiterList
              .where((m) => m.rolle != 'geschaeftsfuehrer')
              .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security_outlined,
                        size: 72,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('Keine Mitarbeiter',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Berechtigungen koennen nur fuer Mitarbeiter vergeben werden (nicht GF)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final ma = filtered[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      ma.vorname.isNotEmpty ? ma.vorname[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  title: Text(ma.displayName,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(ma.rolleLabel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/betrieb/berechtigungen/${ma.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
