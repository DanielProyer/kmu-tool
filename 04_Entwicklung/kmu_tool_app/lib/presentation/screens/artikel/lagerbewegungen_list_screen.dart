import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class LagerbewegungenListScreen extends ConsumerWidget {
  final String artikelId;

  const LagerbewegungenListScreen({super.key, required this.artikelId});

  Color _bewegungColor(String typ) {
    switch (typ) {
      case 'eingang':
        return AppStatusColors.success;
      case 'ausgang':
        return AppStatusColors.error;
      case 'umlagerung':
        return AppStatusColors.info;
      case 'korrektur':
        return AppStatusColors.warning;
      case 'inventur':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }

  IconData _bewegungIcon(String typ) {
    switch (typ) {
      case 'eingang':
        return Icons.arrow_downward;
      case 'ausgang':
        return Icons.arrow_upward;
      case 'umlagerung':
        return Icons.swap_horiz;
      case 'korrektur':
        return Icons.build;
      case 'inventur':
        return Icons.inventory;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final bewegungenAsync =
        ref.watch(lagerbewegungByArtikelProvider(artikelId));
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/artikel/$artikelId'),
        ),
        title: const Text('Lagerbewegungen'),
      ),
      body: bewegungenAsync.when(
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
                  onPressed: () => ref
                      .invalidate(lagerbewegungByArtikelProvider(artikelId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (bewegungen) {
          if (bewegungen.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_vert_outlined,
                      size: 72,
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Lagerbewegungen',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erfasse die erste Bewegung mit dem + Button',
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
              ref.invalidate(lagerbewegungByArtikelProvider(artikelId));
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: bewegungen.length,
              itemBuilder: (context, index) {
                final b = bewegungen[index];
                final color = _bewegungColor(b.bewegungstyp);

                // Build subtitle lines
                String lagerortText = b.lagerortBezeichnung ?? '';
                if (b.bewegungstyp == 'umlagerung' &&
                    b.zielLagerortBezeichnung != null &&
                    b.zielLagerortBezeichnung!.isNotEmpty) {
                  lagerortText += ' \u2192 ${b.zielLagerortBezeichnung}';
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Leading icon
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Icon(
                            _bewegungIcon(b.bewegungstyp),
                            size: 20,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                '${b.bewegungstypLabel}  ${b.menge.toStringAsFixed(b.menge == b.menge.roundToDouble() ? 0 : 2)} Stk',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),

                              // Subtitle line 1: Lagerort
                              if (lagerortText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  lagerortText,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],

                              // Subtitle line 2: Bemerkung
                              if (b.bemerkung != null &&
                                  b.bemerkung!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  b.bemerkung!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Trailing: date
                        if (b.createdAt != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              dateFormat.format(b.createdAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/artikel/$artikelId/bewegungen/neu');
          ref.invalidate(lagerbewegungByArtikelProvider(artikelId));
          ref.invalidate(lagerbestandByArtikelProvider(artikelId));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
