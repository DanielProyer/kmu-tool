import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';
import 'package:kmu_tool_app/presentation/providers/website_providers.dart';
import 'package:kmu_tool_app/services/website/website_service.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/hero_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/beschreibung_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/leistungen_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/ueber_uns_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/team_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/referenzen_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/kundenstimmen_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/galerie_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/faq_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/kontakt_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/offertanfrage_editor.dart';
import 'package:kmu_tool_app/presentation/screens/website/editors/notfalldienst_editor.dart';

class WebsiteDashboardScreen extends ConsumerStatefulWidget {
  const WebsiteDashboardScreen({super.key});

  @override
  ConsumerState<WebsiteDashboardScreen> createState() =>
      _WebsiteDashboardScreenState();
}

class _WebsiteDashboardScreenState
    extends ConsumerState<WebsiteDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(websiteConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Website'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          configAsync.whenOrNull(
                data: (config) {
                  if (config == null) return null;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.palette_outlined),
                        tooltip: 'Design anpassen',
                        onPressed: () => context.push('/website/design'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.mail_outlined),
                        tooltip: 'Anfragen',
                        onPressed: () => context.push('/website/anfragen'),
                      ),
                    ],
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: configAsync.when(
        data: (config) {
          if (config == null) {
            // Noch keine Website -> Redirect zu Setup
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/website/einrichten');
            });
            return const Center(child: CircularProgressIndicator());
          }

          final sectionsAsync =
              ref.watch(websiteSectionsProvider(config.id));
          final unreadAsync =
              ref.watch(websiteUnreadCountProvider(config.id));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(websiteConfigProvider);
              ref.invalidate(websiteSectionsProvider(config.id));
              ref.invalidate(websiteUnreadCountProvider(config.id));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Publish-Status + URL
                _buildPublishCard(config.isPublished, config.slug,
                    config.id),

                const SizedBox(height: 16),

                // Anfragen-Badge
                unreadAsync.whenOrNull(
                      data: (count) {
                        if (count == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            color: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: ListTile(
                              leading: Badge(
                                label: Text('$count'),
                                child:
                                    const Icon(Icons.mail_outlined),
                              ),
                              title: Text(
                                  '$count neue Anfrage${count > 1 ? 'n' : ''}'),
                              trailing: const Icon(
                                  Icons.chevron_right),
                              onTap: () =>
                                  context.push('/website/anfragen'),
                            ),
                          ),
                        );
                      },
                    ) ??
                    const SizedBox.shrink(),

                // Sektionen-Liste
                Text(
                  'Sektionen',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),

                sectionsAsync.when(
                  data: (sections) => _buildSectionsList(sections),
                  loading: () => const Center(
                      child: CircularProgressIndicator()),
                  error: (e, _) => Text('Fehler: $e'),
                ),
              ],
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }

  Widget _buildPublishCard(
      bool isPublished, String slug, String configId) {
    final url = WebsiteService.getPublicUrl(slug);
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPublished ? Icons.public : Icons.public_off,
                  color: isPublished
                      ? Colors.green
                      : colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  isPublished
                      ? 'Website ist online'
                      : 'Website ist offline',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
                const Spacer(),
                Switch(
                  value: isPublished,
                  onChanged: (value) async {
                    if (value) {
                      await WebsiteService.publishWebsite(configId);
                    } else {
                      await WebsiteService.unpublishWebsite(configId);
                    }
                    ref.invalidate(websiteConfigProvider);
                  },
                ),
              ],
            ),
            if (isPublished) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => context.push('/website/vorschau'),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.primary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'URL kopieren',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('URL kopiert')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsList(List<WebsiteSection> sections) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      onReorder: (oldIndex, newIndex) async {
        if (newIndex > oldIndex) newIndex--;
        final list = List<WebsiteSection>.from(sections);
        final item = list.removeAt(oldIndex);
        list.insert(newIndex, item);
        await WebsiteSectionRepository.updateSortierung(list);
        final config = ref.read(websiteConfigProvider).value;
        if (config != null) {
          ref.invalidate(websiteSectionsProvider(config.id));
        }
      },
      itemBuilder: (context, index) {
        final section = sections[index];
        return _SectionTile(
          key: ValueKey(section.id),
          section: section,
          onToggle: (visible) async {
            await WebsiteSectionRepository.updateVisibility(
                section.id, visible);
            final config = ref.read(websiteConfigProvider).value;
            if (config != null) {
              ref.invalidate(websiteSectionsProvider(config.id));
            }
          },
          onEdit: () => _openEditor(section),
        );
      },
    );
  }

  void _openEditor(WebsiteSection section) {
    final configId = ref.read(websiteConfigProvider).value?.id;
    if (configId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        Widget editor;
        switch (section.typ) {
          case 'hero':
            editor = HeroEditor(section: section);
          case 'beschreibung':
            editor = BeschreibungEditor(section: section);
          case 'leistungen':
            editor = LeistungenEditor(section: section);
          case 'ueber_uns':
            editor = UeberUnsEditor(section: section);
          case 'team':
            editor = TeamEditor(section: section);
          case 'referenzen':
            editor = ReferenzenEditor(section: section);
          case 'kundenstimmen':
            editor = KundenstimmenEditor(section: section);
          case 'galerie':
            editor = GalerieEditor(
                section: section, configId: configId);
          case 'faq':
            editor = FaqEditor(section: section);
          case 'kontakt':
            editor = KontaktEditor(section: section);
          case 'offertanfrage':
            editor = OffertanfrageEditor(section: section);
          case 'notfalldienst':
            editor = NotfalldienstEditor(section: section);
          default:
            editor = Center(child: Text('Editor fuer ${section.typLabel} nicht verfuegbar'));
        }
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return editor;
          },
        );
      },
    ).then((_) {
      ref.invalidate(websiteSectionsProvider(configId));
    });
  }
}

class _SectionTile extends StatelessWidget {
  final WebsiteSection section;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;

  const _SectionTile({
    super.key,
    required this.section,
    required this.onToggle,
    required this.onEdit,
  });

  IconData _iconForType(String typ) {
    switch (typ) {
      case 'hero':
        return Icons.image;
      case 'beschreibung':
        return Icons.description;
      case 'leistungen':
        return Icons.build;
      case 'ueber_uns':
        return Icons.info_outline;
      case 'team':
        return Icons.group;
      case 'referenzen':
        return Icons.work_history;
      case 'kundenstimmen':
        return Icons.format_quote;
      case 'galerie':
        return Icons.photo_library;
      case 'faq':
        return Icons.help_outline;
      case 'kontakt':
        return Icons.phone;
      case 'offertanfrage':
        return Icons.request_quote;
      case 'notfalldienst':
        return Icons.emergency;
      default:
        return Icons.widgets;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _iconForType(section.typ),
          color: section.isVisible
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Text(
          section.titel ?? section.typLabel,
          style: TextStyle(
            color: section.isVisible
                ? null
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        subtitle: Text(section.typLabel),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: section.isVisible,
              onChanged: onToggle,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}
