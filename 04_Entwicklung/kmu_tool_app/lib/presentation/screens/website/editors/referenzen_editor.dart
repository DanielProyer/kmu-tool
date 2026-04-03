import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class ReferenzenEditor extends StatefulWidget {
  final WebsiteSection section;
  const ReferenzenEditor({super.key, required this.section});

  @override
  State<ReferenzenEditor> createState() => _ReferenzenEditorState();
}

class _ReferenzenEditorState extends State<ReferenzenEditor> {
  late List<Map<String, String>> _projekte;
  final _titelCtrl = TextEditingController();
  final _beschreibungCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.section.content['projekte'] as List? ?? [];
    _projekte = raw
        .map((p) => {
              'titel': (p['titel'] ?? '') as String,
              'beschreibung': (p['beschreibung'] ?? '') as String,
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
      _projekte.add({
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
        content: {'projekte': _projekte},
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
                child: Text('Referenzen',
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
                ...List.generate(_projekte.length, (i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(_projekte[i]['titel'] ?? ''),
                      subtitle: _projekte[i]['beschreibung']?.isNotEmpty ==
                              true
                          ? Text(_projekte[i]['beschreibung']!)
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _projekte.removeAt(i)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: _titelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Projekttitel',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _beschreibungCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Beschreibung',
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
