import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/mitarbeiter.dart';
import 'package:kmu_tool_app/presentation/providers/mitarbeiter_provider.dart';
import 'package:kmu_tool_app/presentation/widgets/mitarbeiter_einladen_dialog.dart';

class MitarbeiterListScreen extends ConsumerWidget {
  const MitarbeiterListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final mitarbeiterAsync = ref.watch(mitarbeiterListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/einstellungen'),
        ),
        title: const Text('Mitarbeiter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'App-Zugang einladen',
            onPressed: () async {
              final created =
                  await MitarbeiterEinladenDialog.show(context);
              if (created == true) {
                ref.invalidate(mitarbeiterListProvider);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Mitarbeiter erfassen',
            onPressed: () async {
              await context.push('/einstellungen/mitarbeiter/neu');
              ref.invalidate(mitarbeiterListProvider);
            },
          ),
        ],
      ),
      body: mitarbeiterAsync.when(
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
                  onPressed: () => ref.invalidate(mitarbeiterListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (mitarbeiterList) {
          if (mitarbeiterList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 72,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Mitarbeiter erfasst',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle deinen ersten Mitarbeiter mit dem + Button',
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
              ref.invalidate(mitarbeiterListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: mitarbeiterList.length,
              itemBuilder: (context, index) {
                final mitarbeiter = mitarbeiterList[index];
                return _MitarbeiterCard(
                  mitarbeiter: mitarbeiter,
                  onTap: () async {
                    await context.push(
                        '/einstellungen/mitarbeiter/${mitarbeiter.id}/bearbeiten');
                    ref.invalidate(mitarbeiterListProvider);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/einstellungen/mitarbeiter/neu');
          ref.invalidate(mitarbeiterListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MitarbeiterCard extends StatelessWidget {
  final Mitarbeiter mitarbeiter;
  final VoidCallback onTap;

  const _MitarbeiterCard({
    required this.mitarbeiter,
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
                  mitarbeiter.vorname.isNotEmpty
                      ? mitarbeiter.vorname[0].toUpperCase()
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
                      mitarbeiter.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mitarbeiter.rolleLabel,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    if (mitarbeiter.telefon != null &&
                        mitarbeiter.telefon!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mitarbeiter.telefon!,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
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
