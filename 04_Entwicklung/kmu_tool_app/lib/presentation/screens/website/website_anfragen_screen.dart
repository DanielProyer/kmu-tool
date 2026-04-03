import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/data/models/website_anfrage.dart';
import 'package:kmu_tool_app/data/repositories/website_anfrage_repository.dart';
import 'package:kmu_tool_app/presentation/providers/website_providers.dart';

class WebsiteAnfragenScreen extends ConsumerWidget {
  const WebsiteAnfragenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(websiteConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anfragen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: configAsync.when(
        data: (config) {
          if (config == null) {
            return const Center(child: Text('Keine Website konfiguriert'));
          }
          final anfragenAsync =
              ref.watch(websiteAnfragenProvider(config.id));

          return anfragenAsync.when(
            data: (anfragen) {
              if (anfragen.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mail_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('Noch keine Anfragen',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Anfragen von Ihrer Website erscheinen hier.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(websiteAnfragenProvider(config.id));
                  ref.invalidate(websiteUnreadCountProvider(config.id));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: anfragen.length,
                  itemBuilder: (context, index) {
                    final anfrage = anfragen[index];
                    return _AnfrageTile(
                      anfrage: anfrage,
                      onTap: () => _showDetail(context, ref, anfrage,
                          config.id),
                    );
                  },
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref,
      WebsiteAnfrage anfrage, String configId) {
    // Mark as read
    if (!anfrage.gelesen) {
      WebsiteAnfrageRepository.markAsRead(anfrage.id);
      ref.invalidate(websiteAnfragenProvider(configId));
      ref.invalidate(websiteUnreadCountProvider(configId));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(anfrage.typLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  _detailRow(context, 'Name', anfrage.name),
                  _detailRow(context, 'E-Mail', anfrage.email),
                  if (anfrage.telefon != null)
                    _detailRow(context, 'Telefon', anfrage.telefon!),
                  if (anfrage.nachricht != null &&
                      anfrage.nachricht!.isNotEmpty)
                    _detailRow(context, 'Nachricht', anfrage.nachricht!),
                  if (anfrage.details.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Details',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...anfrage.details.entries.map((e) =>
                        _detailRow(context, e.key, e.value.toString())),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(anfrage.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _AnfrageTile extends StatelessWidget {
  final WebsiteAnfrage anfrage;
  final VoidCallback onTap;

  const _AnfrageTile({required this.anfrage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: anfrage.gelesen
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            anfrage.typ == 'offerte'
                ? Icons.request_quote
                : Icons.mail_outlined,
            color: anfrage.gelesen
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          anfrage.name,
          style: TextStyle(
            fontWeight: anfrage.gelesen ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Text(
          anfrage.typLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Text(
          _formatShortDate(anfrage.createdAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatShortDate(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day}.${dt.month}.';
  }
}
