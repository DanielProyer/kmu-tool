import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/data/repositories/lagerort_repository.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class LagerortListScreen extends ConsumerStatefulWidget {
  const LagerortListScreen({super.key});

  @override
  ConsumerState<LagerortListScreen> createState() =>
      _LagerortListScreenState();
}

class _LagerortListScreenState extends ConsumerState<LagerortListScreen> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lagerorteAsync = ref.watch(lagerortListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Lagerorte'),
      ),
      body: lagerorteAsync.when(
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
                  onPressed: () => ref.invalidate(lagerortListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (lagerorte) {
          if (lagerorte.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      size: 72,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Lagerorte erfasst',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle deinen ersten Lagerort mit dem + Button',
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
              ref.invalidate(lagerortListProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: lagerorte.length,
              itemBuilder: (context, index) {
                final lagerort = lagerorte[index];
                return _LagerortCard(
                  bezeichnung: lagerort.bezeichnung,
                  typ: lagerort.typ,
                  typLabel: lagerort.typLabel,
                  istStandard: lagerort.istStandard,
                  onEdit: () async {
                    await context
                        .push('/lagerorte/${lagerort.id}/bearbeiten');
                    ref.invalidate(lagerortListProvider);
                  },
                  onDelete: () =>
                      _confirmDelete(context, ref, lagerort.id, lagerort.bezeichnung),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/lagerorte/neu');
          ref.invalidate(lagerortListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String id, String bezeichnung) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lagerort loeschen?'),
        content: Text(
          'Moechtest du den Lagerort "$bezeichnung" wirklich loeschen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppStatusColors.error,
            ),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await LagerortRepository.delete(id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Lagerort geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          ref.invalidate(lagerortListProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Loeschen: $e'),
              backgroundColor: AppStatusColors.error,
            ),
          );
        }
      }
    }
  }
}

// ─── Lagerort Card ───

class _LagerortCard extends StatelessWidget {
  final String bezeichnung;
  final String typ;
  final String typLabel;
  final bool istStandard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LagerortCard({
    required this.bezeichnung,
    required this.typ,
    required this.typLabel,
    required this.istStandard,
    required this.onEdit,
    required this.onDelete,
  });

  Color _typColor(String typ) {
    switch (typ) {
      case 'lager':
        return AppStatusColors.info;
      case 'fahrzeug':
        return AppStatusColors.warning;
      case 'baustelle':
        return AppStatusColors.success;
      default:
        return AppStatusColors.storniert;
    }
  }

  IconData _typIcon(String typ) {
    switch (typ) {
      case 'lager':
        return Icons.warehouse_outlined;
      case 'fahrzeug':
        return Icons.local_shipping_outlined;
      case 'baustelle':
        return Icons.construction_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _typColor(typ);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(_typIcon(typ), color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          bezeichnung,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (istStandard)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.star,
                            size: 18,
                            color: AppStatusColors.warning,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      typLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 20, color: colorScheme.onSurfaceVariant),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 20, color: AppStatusColors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
