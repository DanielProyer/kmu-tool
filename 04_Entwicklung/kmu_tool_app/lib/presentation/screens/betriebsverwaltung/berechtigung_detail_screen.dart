import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/mitarbeiter_berechtigung.dart';
import 'package:kmu_tool_app/data/repositories/mitarbeiter_berechtigung_repository.dart';
import 'package:kmu_tool_app/presentation/providers/betriebsverwaltung_provider.dart';
import 'package:kmu_tool_app/presentation/providers/mitarbeiter_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

class BerechtigungDetailScreen extends ConsumerStatefulWidget {
  final String mitarbeiterId;

  const BerechtigungDetailScreen({super.key, required this.mitarbeiterId});

  @override
  ConsumerState<BerechtigungDetailScreen> createState() =>
      _BerechtigungDetailScreenState();
}

class _BerechtigungDetailScreenState
    extends ConsumerState<BerechtigungDetailScreen> {
  final Map<String, bool> _lesen = {};
  final Map<String, bool> _schreiben = {};
  bool _isLoading = false;
  String _mitarbeiterName = '';

  @override
  void initState() {
    super.initState();
    // Init mit false fuer alle Module
    for (final modul in MitarbeiterBerechtigung.allModule) {
      _lesen[modul] = false;
      _schreiben[modul] = false;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // Name laden
      final ma = await ref.read(mitarbeiterProvider(widget.mitarbeiterId).future);
      if (ma != null && mounted) {
        _mitarbeiterName = ma.displayName;
      }

      // Berechtigungen laden
      final berechtigungen =
          await MitarbeiterBerechtigungRepository.getForMitarbeiter(
              widget.mitarbeiterId);
      if (mounted) {
        for (final b in berechtigungen) {
          _lesen[b.modul] = b.lesen;
          _schreiben[b.modul] = b.schreiben;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppStatusColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final userId = await BetriebService.getDataOwnerId();
      final berechtigungen = MitarbeiterBerechtigung.allModule.map((modul) {
        return MitarbeiterBerechtigung(
          id: const Uuid().v4(),
          userId: userId,
          mitarbeiterId: widget.mitarbeiterId,
          modul: modul,
          lesen: _lesen[modul] ?? false,
          schreiben: _schreiben[modul] ?? false,
        );
      }).toList();

      // Alte loeschen, neue speichern
      await MitarbeiterBerechtigungRepository.deleteForMitarbeiter(
          widget.mitarbeiterId);
      await MitarbeiterBerechtigungRepository.saveAll(berechtigungen);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Berechtigungen gespeichert'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(
            mitarbeiterBerechtigungenProvider(widget.mitarbeiterId));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppStatusColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mitarbeiterName.isEmpty
            ? 'Berechtigungen'
            : _mitarbeiterName),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Speichern'),
          ),
        ],
      ),
      body: _isLoading && _mitarbeiterName.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                          flex: 3,
                          child: Text('Modul',
                              style: TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                        child: Text('Lesen',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant)),
                      ),
                      Expanded(
                        child: Text('Schreiben',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...MitarbeiterBerechtigung.allModule.map((modul) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            MitarbeiterBerechtigung.modulLabel(modul),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        Expanded(
                          child: Checkbox(
                            value: _lesen[modul] ?? false,
                            onChanged: (v) {
                              setState(() {
                                _lesen[modul] = v ?? false;
                                // Schreiben impliziert Lesen
                                if (!(v ?? false)) {
                                  _schreiben[modul] = false;
                                }
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: Checkbox(
                            value: _schreiben[modul] ?? false,
                            onChanged: (v) {
                              setState(() {
                                _schreiben[modul] = v ?? false;
                                // Schreiben setzt Lesen automatisch
                                if (v ?? false) {
                                  _lesen[modul] = true;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            for (final m in MitarbeiterBerechtigung.allModule) {
                              _lesen[m] = true;
                              _schreiben[m] = true;
                            }
                          });
                        },
                        child: const Text('Alle aktivieren'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            for (final m in MitarbeiterBerechtigung.allModule) {
                              _lesen[m] = false;
                              _schreiben[m] = false;
                            }
                          });
                        },
                        child: const Text('Alle deaktivieren'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}
