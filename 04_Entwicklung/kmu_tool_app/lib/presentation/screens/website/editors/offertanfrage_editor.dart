import 'package:flutter/material.dart';
import 'package:kmu_tool_app/data/models/website_section.dart';
import 'package:kmu_tool_app/data/repositories/website_section_repository.dart';

class OffertanfrageEditor extends StatefulWidget {
  final WebsiteSection section;
  const OffertanfrageEditor({super.key, required this.section});

  @override
  State<OffertanfrageEditor> createState() => _OffertanfrageEditorState();
}

class _OffertanfrageEditorState extends State<OffertanfrageEditor> {
  late List<String> _leistungen;
  late bool _zeigeWunschtermin;
  final _leistungCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.section.content['leistungen'] as List? ?? [];
    _leistungen = raw.map((l) => l.toString()).toList();
    _zeigeWunschtermin =
        widget.section.content['zeige_wunschtermin'] ?? true;
  }

  @override
  void dispose() {
    _leistungCtrl.dispose();
    super.dispose();
  }

  void _add() {
    if (_leistungCtrl.text.trim().isEmpty) return;
    setState(() {
      _leistungen.add(_leistungCtrl.text.trim());
      _leistungCtrl.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.section.copyWith(
        content: {
          'leistungen': _leistungen,
          'zeige_wunschtermin': _zeigeWunschtermin,
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
                child: Text('Offertanfrage',
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
                SwitchListTile(
                  title: const Text('Wunschtermin anzeigen'),
                  subtitle: const Text(
                      'Besucher koennen einen Wunschtermin angeben'),
                  value: _zeigeWunschtermin,
                  onChanged: (v) =>
                      setState(() => _zeigeWunschtermin = v),
                ),
                const SizedBox(height: 16),
                Text('Leistungen zur Auswahl',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ...List.generate(_leistungen.length, (i) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      dense: true,
                      title: Text(_leistungen[i]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () =>
                            setState(() => _leistungen.removeAt(i)),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _leistungCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Leistung hinzufuegen',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
