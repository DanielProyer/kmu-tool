import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class KundenstimmenEditor extends StatefulWidget {
  final WebsiteSection section;
  const KundenstimmenEditor({super.key, required this.section});

  @override
  State<KundenstimmenEditor> createState() => _KundenstimmenEditorState();
}

class _KundenstimmenEditorState extends State<KundenstimmenEditor> {
  late List<Map<String, dynamic>> _testimonials;
  final _nameCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  int _sterne = 5;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.section.content['testimonials'] as List? ?? [];
    _testimonials = raw
        .map((t) => {
              'name': (t['name'] ?? '') as String,
              'text': (t['text'] ?? '') as String,
              'sterne': (t['sterne'] ?? 5) as int,
            })
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_nameCtrl.text.trim().isEmpty || _textCtrl.text.trim().isEmpty) return;
    setState(() {
      _testimonials.add({
        'name': _nameCtrl.text.trim(),
        'text': _textCtrl.text.trim(),
        'sterne': _sterne,
      });
      _nameCtrl.clear();
      _textCtrl.clear();
      _sterne = 5;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {'testimonials': _testimonials},
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
                child: Text('Kundenstimmen',
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
                ...List.generate(_testimonials.length, (i) {
                  final t = _testimonials[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(t['name'] as String),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['text'] as String, maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          Row(
                            children: List.generate(
                              t['sterne'] as int,
                              (_) => const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _testimonials.removeAt(i)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kundenname',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _textCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bewertungstext',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Sterne: '),
                    ...List.generate(5, (i) {
                      return IconButton(
                        icon: Icon(
                          i < _sterne ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () =>
                            setState(() => _sterne = i + 1),
                      );
                    }),
                  ],
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
