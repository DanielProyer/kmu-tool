import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class KontaktEditor extends StatefulWidget {
  final WebsiteSection section;
  const KontaktEditor({super.key, required this.section});

  @override
  State<KontaktEditor> createState() => _KontaktEditorState();
}

class _KontaktEditorState extends State<KontaktEditor> {
  late bool _zeigeKarte;
  late bool _zeigeFormular;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _zeigeKarte = widget.section.content['zeige_karte'] ?? true;
    _zeigeFormular = widget.section.content['zeige_formular'] ?? true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {
          'zeige_karte': _zeigeKarte,
          'zeige_formular': _zeigeFormular,
        },
      );
      await WebsiteSectionRepository.save(updated);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Kontakt',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Speichern'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),
          Text('Die Kontaktdaten werden automatisch aus Ihrem Profil uebernommen.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          SwitchListTile(
            title: const Text('Kontaktformular anzeigen'),
            subtitle: const Text('Besucher koennen Ihnen direkt eine Nachricht senden'),
            value: _zeigeFormular,
            onChanged: (v) => setState(() => _zeigeFormular = v),
          ),
          SwitchListTile(
            title: const Text('Karte anzeigen'),
            subtitle: const Text('Zeigt Ihren Standort auf einer Karte'),
            value: _zeigeKarte,
            onChanged: (v) => setState(() => _zeigeKarte = v),
          ),
        ],
      ),
    );
  }
}
