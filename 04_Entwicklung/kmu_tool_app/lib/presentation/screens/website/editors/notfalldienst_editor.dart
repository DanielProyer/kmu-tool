import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class NotfalldienstEditor extends StatefulWidget {
  final WebsiteSection section;
  const NotfalldienstEditor({super.key, required this.section});

  @override
  State<NotfalldienstEditor> createState() => _NotfalldienstEditorState();
}

class _NotfalldienstEditorState extends State<NotfalldienstEditor> {
  late final TextEditingController _textCtrl;
  late final TextEditingController _telefonCtrl;
  late final TextEditingController _zeitenCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.section.content;
    _textCtrl = TextEditingController(text: c['text'] ?? '');
    _telefonCtrl = TextEditingController(text: c['telefon'] ?? '');
    _zeitenCtrl = TextEditingController(text: c['zeiten'] ?? '');
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _telefonCtrl.dispose();
    _zeitenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {
          'text': _textCtrl.text.trim(),
          'telefon': _telefonCtrl.text.trim(),
          'zeiten': _zeitenCtrl.text.trim(),
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
                child: Text('Notfalldienst',
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
            controller: _textCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Beschreibung',
              hintText: 'z.B. 24h Notfalldienst',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _telefonCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Notfall-Telefon',
              hintText: '079 123 45 67',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _zeitenCtrl,
            decoration: const InputDecoration(
              labelText: 'Erreichbarkeit',
              hintText: 'z.B. Mo-So, 0-24 Uhr',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
