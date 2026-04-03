import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class HeroEditor extends StatefulWidget {
  final WebsiteSection section;
  const HeroEditor({super.key, required this.section});

  @override
  State<HeroEditor> createState() => _HeroEditorState();
}

class _HeroEditorState extends State<HeroEditor> {
  late final TextEditingController _headlineCtrl;
  late final TextEditingController _sublineCtrl;
  late final TextEditingController _ctaTextCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.section.content;
    _headlineCtrl = TextEditingController(text: c['headline'] ?? '');
    _sublineCtrl = TextEditingController(text: c['subline'] ?? '');
    _ctaTextCtrl = TextEditingController(
        text: c['cta_text'] ?? 'Offerte anfragen');
  }

  @override
  void dispose() {
    _headlineCtrl.dispose();
    _sublineCtrl.dispose();
    _ctaTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {
          ...widget.section.content,
          'headline': _headlineCtrl.text.trim(),
          'subline': _sublineCtrl.text.trim(),
          'cta_text': _ctaTextCtrl.text.trim(),
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
                child: Text('Hero-Bereich',
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
          TextField(
            controller: _headlineCtrl,
            decoration: const InputDecoration(
              labelText: 'Headline',
              hintText: 'z.B. Willkommen bei Muster GmbH',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sublineCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Subline',
              hintText: 'Kurzer Slogan oder Beschreibung',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctaTextCtrl,
            decoration: const InputDecoration(
              labelText: 'Button-Text',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
