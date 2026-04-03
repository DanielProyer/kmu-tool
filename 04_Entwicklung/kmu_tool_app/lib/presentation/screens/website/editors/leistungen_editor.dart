import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class LeistungenEditor extends StatefulWidget {
  final WebsiteSection section;
  const LeistungenEditor({super.key, required this.section});

  @override
  State<LeistungenEditor> createState() => _LeistungenEditorState();
}

class _LeistungenEditorState extends State<LeistungenEditor> {
  late List<Map<String, String>> _items;
  final _titelCtrl = TextEditingController();
  final _beschreibungCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final rawItems = widget.section.content['items'] as List? ?? [];
    _items = rawItems
        .map((i) => {
              'titel': (i['titel'] ?? '') as String,
              'beschreibung': (i['beschreibung'] ?? '') as String,
            })
        .toList();
  }

  @override
  void dispose() {
    _titelCtrl.dispose();
    _beschreibungCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_titelCtrl.text.trim().isEmpty) return;
    setState(() {
      _items.add({
        'titel': _titelCtrl.text.trim(),
        'beschreibung': _beschreibungCtrl.text.trim(),
      });
      _titelCtrl.clear();
      _beschreibungCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {'items': _items},
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
                child: Text('Leistungen',
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
                ...List.generate(_items.length, (i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(_items[i]['titel'] ?? ''),
                      subtitle: _items[i]['beschreibung']?.isNotEmpty == true
                          ? Text(_items[i]['beschreibung']!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _items.removeAt(i)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: _titelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Leistung',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _beschreibungCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung (optional)',
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
