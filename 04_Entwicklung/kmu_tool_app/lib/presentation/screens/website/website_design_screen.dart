import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/data/repositories/website_config_repository.dart';
import 'package:kmu_tool_app/presentation/providers/website_providers.dart';

class WebsiteDesignScreen extends ConsumerStatefulWidget {
  const WebsiteDesignScreen({super.key});

  @override
  ConsumerState<WebsiteDesignScreen> createState() =>
      _WebsiteDesignScreenState();
}

class _WebsiteDesignScreenState extends ConsumerState<WebsiteDesignScreen> {
  String? _template;
  String? _color;
  String? _font;
  bool _saving = false;

  final _fonts = ['Inter', 'Merriweather', 'Nunito', 'Roboto Slab', 'Source Sans 3'];
  final _colors = [
    '#2563EB', '#059669', '#D97706', '#DC2626', '#7C3AED',
    '#0891B2', '#4F46E5', '#BE185D', '#1E40AF', '#065F46',
  ];

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(websiteConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Design anpassen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          configAsync.whenOrNull(
                data: (config) {
                  if (config == null) return null;
                  return TextButton(
                    onPressed: _saving ? null : () => _save(config.id),
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Speichern'),
                  );
                },
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: configAsync.when(
        data: (config) {
          if (config == null) return const Center(child: Text('Keine Website'));
          _template ??= config.designTemplate;
          _color ??= config.primaerfarbe;
          _font ??= config.schriftart;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Template
              Text('Template',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...['modern', 'klassisch', 'handwerk'].map((t) {
                final labels = {
                  'modern': 'Modern',
                  'klassisch': 'Klassisch',
                  'handwerk': 'Handwerk',
                };
                return ListTile(
                  leading: Icon(
                    _template == t ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: _template == t ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(labels[t]!),
                  onTap: () => setState(() => _template = t),
                );
              }),

              const Divider(height: 32),

              // Farbe
              Text('Hauptfarbe',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _colors.map((c) {
                  final colorVal =
                      Color(int.parse(c.replaceFirst('#', '0xFF')));
                  return GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorVal,
                        shape: BoxShape.circle,
                        border: _color == c
                            ? Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface,
                                width: 3)
                            : null,
                      ),
                      child: _color == c
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const Divider(height: 32),

              // Schriftart
              Text('Schriftart',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ..._fonts.map((f) {
                return ListTile(
                  leading: Icon(
                    _font == f ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: _font == f ? Theme.of(context).colorScheme.primary : null,
                  ),
                  title: Text(f),
                  onTap: () => setState(() => _font = f),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }

  Future<void> _save(String configId) async {
    setState(() => _saving = true);
    try {
      final config = ref.read(websiteConfigProvider).value!;
      final updated = config.copyWith(
        designTemplate: _template,
        primaerfarbe: _color,
        schriftart: _font,
      );
      await WebsiteConfigRepository.save(updated);
      ref.invalidate(websiteConfigProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Design gespeichert')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
