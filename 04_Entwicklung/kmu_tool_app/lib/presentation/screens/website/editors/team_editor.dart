import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class TeamEditor extends StatefulWidget {
  final WebsiteSection section;
  const TeamEditor({super.key, required this.section});

  @override
  State<TeamEditor> createState() => _TeamEditorState();
}

class _TeamEditorState extends State<TeamEditor> {
  late List<Map<String, String>> _mitglieder;
  final _nameCtrl = TextEditingController();
  final _rolleCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.section.content['mitglieder'] as List? ?? [];
    _mitglieder = raw
        .map((m) => {
              'name': (m['name'] ?? '') as String,
              'rolle': (m['rolle'] ?? '') as String,
            })
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rolleCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _mitglieder.add({
        'name': _nameCtrl.text.trim(),
        'rolle': _rolleCtrl.text.trim(),
      });
      _nameCtrl.clear();
      _rolleCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {'mitglieder': _mitglieder},
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
                child: Text('Team',
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
                ...List.generate(_mitglieder.length, (i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                          child: Icon(Icons.person)),
                      title: Text(_mitglieder[i]['name'] ?? ''),
                      subtitle: Text(_mitglieder[i]['rolle'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => _mitglieder.removeAt(i)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _rolleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Rolle / Funktion',
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
