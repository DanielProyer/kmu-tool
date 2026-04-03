import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class FaqEditor extends StatefulWidget {
  final WebsiteSection section;
  const FaqEditor({super.key, required this.section});

  @override
  State<FaqEditor> createState() => _FaqEditorState();
}

class _FaqEditorState extends State<FaqEditor> {
  late List<Map<String, String>> _fragen;
  final _frageCtrl = TextEditingController();
  final _antwortCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.section.content['fragen'] as List? ?? [];
    _fragen = raw
        .map((f) => {
              'frage': (f['frage'] ?? '') as String,
              'antwort': (f['antwort'] ?? '') as String,
            })
        .toList();
  }

  @override
  void dispose() {
    _frageCtrl.dispose();
    _antwortCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_frageCtrl.text.trim().isEmpty) return;
    setState(() {
      _fragen.add({
        'frage': _frageCtrl.text.trim(),
        'antwort': _antwortCtrl.text.trim(),
      });
      _frageCtrl.clear();
      _antwortCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {'fragen': _fragen},
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
                child: Text('FAQ',
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
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                ...List.generate(_fragen.length, (i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text(_fragen[i]['frage'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _fragen.removeAt(i)),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(_fragen[i]['antwort'] ?? ''),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: _frageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Frage',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _antwortCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Antwort',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _add,
                    icon: const Icon(Icons.add),
                    label: const Text('Hinzufuegen'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
