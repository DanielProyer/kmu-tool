import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/bankverbindung.dart';
import 'package:kmu_tool_app/presentation/providers/betriebsverwaltung_provider.dart';

class BankverbindungenListScreen extends ConsumerWidget {
  const BankverbindungenListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final listAsync = ref.watch(bankverbindungenListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bankverbindungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Neue Bankverbindung',
            onPressed: () async {
              await context.push('/betrieb/bankverbindungen/neu');
              ref.invalidate(bankverbindungenListProvider);
            },
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text('Fehler beim Laden',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(error.toString(),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(bankverbindungenListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_outlined,
                        size: 72,
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    Text('Keine Bankverbindungen',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Erstelle eine neue Bankverbindung mit dem + Button',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(bankverbindungenListProvider),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 88),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                return _BankCard(
                  item: item,
                  onTap: () async {
                    await context.push(
                        '/betrieb/bankverbindungen/${item.id}/bearbeiten');
                    ref.invalidate(bankverbindungenListProvider);
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/betrieb/bankverbindungen/neu');
          ref.invalidate(bankverbindungenListProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  final Bankverbindung item;
  final VoidCallback onTap;

  const _BankCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                  item.istHauptkonto
                      ? Icons.star
                      : Icons.account_balance_outlined,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.bezeichnung,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (item.istHauptkonto) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Haupt',
                              style: TextStyle(
                                fontSize: 11,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.iban,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    if (item.bankName != null && item.bankName!.isNotEmpty)
                      Text(
                        item.bankName!,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
