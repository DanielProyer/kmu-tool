import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:kmu_tool_app/data/repositories/user_profile_repository.dart';
import 'package:kmu_tool_app/data/repositories/website_config_repository.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';
import 'package:kmu_tool_app/presentation/providers/website_providers.dart';
import 'package:kmu_tool_app/services/website/website_service.dart';

class WebsiteSetupScreen extends ConsumerStatefulWidget {
  const WebsiteSetupScreen({super.key});

  @override
  ConsumerState<WebsiteSetupScreen> createState() =>
      _WebsiteSetupScreenState();
}

class _WebsiteSetupScreenState extends ConsumerState<WebsiteSetupScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;

  // Schritt 1
  final _firmenNameController = TextEditingController();
  final _untertitelController = TextEditingController();
  Uint8List? _logoBytes;
  String? _logoFileName;

  // Schritt 2
  final _beschreibungController = TextEditingController();
  final List<Map<String, String>> _leistungen = [];
  final _leistungTitelController = TextEditingController();

  // Schritt 3
  String _selectedTemplate = 'modern';
  String _selectedColor = '#2563EB';

  final _colors = [
    '#2563EB', '#059669', '#D97706', '#DC2626', '#7C3AED',
    '#0891B2', '#4F46E5', '#BE185D',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await UserProfileRepository().get();
    if (profile != null && mounted) {
      setState(() {
        _firmenNameController.text = profile.firmaName;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firmenNameController.dispose();
    _untertitelController.dispose();
    _beschreibungController.dispose();
    _leistungTitelController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createWebsite() async {
    if (_firmenNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Firmenname eingeben')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final profile = await UserProfileRepository().get();
      if (profile == null) throw Exception('Profil nicht gefunden');

      final config = await WebsiteService.initializeWebsite(profile);

      // Logo hochladen falls vorhanden
      String? logoPath;
      if (_logoBytes != null && _logoFileName != null) {
        logoPath = await WebsiteService.uploadLogo(
          configId: config.id,
          bytes: _logoBytes!,
          fileName: _logoFileName!,
        );
      }

      // Config aktualisieren mit Wizard-Daten
      final updated = config.copyWith(
        firmenName: _firmenNameController.text.trim(),
        untertitel: _untertitelController.text.trim().isEmpty
            ? null
            : _untertitelController.text.trim(),
        designTemplate: _selectedTemplate,
        primaerfarbe: _selectedColor,
        logoPath: logoPath,
      );
      await WebsiteConfigRepository.save(updated);

      // Beschreibung + Leistungen in Sektionen speichern
      final sections =
          await WebsiteSectionRepository.getByConfig(config.id);

      if (_beschreibungController.text.trim().isNotEmpty) {
        final beschreibung =
            sections.where((s) => s.typ == 'beschreibung').firstOrNull;
        if (beschreibung != null) {
          await WebsiteSectionRepository.save(beschreibung.copyWith(
            content: {'text': _beschreibungController.text.trim()},
          ));
        }
      }

      if (_leistungen.isNotEmpty) {
        final leistungen =
            sections.where((s) => s.typ == 'leistungen').firstOrNull;
        if (leistungen != null) {
          await WebsiteSectionRepository.save(leistungen.copyWith(
            content: {
              'items': _leistungen
                  .map((l) => {
                        'titel': l['titel'],
                        'beschreibung': l['beschreibung'] ?? '',
                      })
                  .toList(),
            },
          ));
        }
      }

      ref.invalidate(websiteConfigProvider);

      if (mounted) context.go('/website');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _logoBytes = file.bytes;
          _logoFileName = file.name;
        });
      }
    }
  }

  void _addLeistung() {
    final titel = _leistungTitelController.text.trim();
    if (titel.isEmpty) return;
    setState(() {
      _leistungen.add({'titel': titel, 'beschreibung': ''});
      _leistungTitelController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Website einrichten'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          // Stepper
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    decoration: BoxDecoration(
                      color: i <= _currentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),

          // Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: _prevStep,
                    child: const Text('Zurueck'),
                  ),
                const Spacer(),
                if (_currentStep < 2)
                  FilledButton(
                    onPressed: _nextStep,
                    child: const Text('Weiter'),
                  ),
                if (_currentStep == 2)
                  FilledButton(
                    onPressed: _isLoading ? null : _createWebsite,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Text('Website erstellen'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Grunddaten',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text('Diese Informationen erscheinen auf Ihrer Website.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: _logoBytes != null
                  ? const Icon(Icons.check_circle,
                      size: 48, color: Colors.green)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 36,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant),
                        const SizedBox(height: 4),
                        Text('Logo',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant)),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _firmenNameController,
          decoration: const InputDecoration(
              labelText: 'Firmenname', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _untertitelController,
          decoration: const InputDecoration(
            labelText: 'Untertitel (optional)',
            hintText: 'z.B. Ihr Sanitaer in Zuerich',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Beschreibung & Leistungen',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        TextField(
          controller: _beschreibungController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Kurzbeschreibung',
            hintText: 'Was macht Ihr Betrieb?',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        Text('Leistungen',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...List.generate(_leistungen.length, (i) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(_leistungen[i]['titel'] ?? ''),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => _leistungen.removeAt(i)),
              ),
            ),
          );
        }),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _leistungTitelController,
                decoration: const InputDecoration(
                  labelText: 'Leistung hinzufuegen',
                  hintText: 'z.B. Sanitaer',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addLeistung(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addLeistung,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Design waehlen',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
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
          final descs = {
            'modern': 'Klare Linien, grosse Bilder, zeitgemaess',
            'klassisch': 'Elegantes Design, professionell',
            'handwerk': 'Robustes Design, warme Farben',
          };
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _selectedTemplate == t
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: _selectedTemplate == t ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: Icon(
                _selectedTemplate == t ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: _selectedTemplate == t ? Theme.of(context).colorScheme.primary : null,
              ),
              title: Text(labels[t]!),
              subtitle: Text(descs[t]!),
              onTap: () => setState(() => _selectedTemplate = t),
            ),
          );
        }),
        const SizedBox(height: 24),
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
              onTap: () => setState(() => _selectedColor = c),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorVal,
                  shape: BoxShape.circle,
                  border: _selectedColor == c
                      ? Border.all(
                          color:
                              Theme.of(context).colorScheme.onSurface,
                          width: 3)
                      : null,
                ),
                child: _selectedColor == c
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
