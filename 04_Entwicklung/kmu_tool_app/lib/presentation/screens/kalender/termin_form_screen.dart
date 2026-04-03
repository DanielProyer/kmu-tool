import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/termin.dart';
import 'package:kmu_tool_app/data/repositories/termin_repository.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';
import 'package:kmu_tool_app/presentation/providers/termin_provider.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class TerminFormScreen extends ConsumerStatefulWidget {
  final String? terminId;

  const TerminFormScreen({super.key, this.terminId});

  @override
  ConsumerState<TerminFormScreen> createState() => _TerminFormScreenState();
}

class _TerminFormScreenState extends ConsumerState<TerminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titelController = TextEditingController();
  final _beschreibungController = TextEditingController();
  final _ortController = TextEditingController();
  final _notizenController = TextEditingController();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  bool _isLoading = false;
  bool _isEdit = false;
  Termin? _existingTermin;

  DateTime _datum = DateTime.now();
  bool _ganztaegig = false;
  TimeOfDay? _startZeit;
  TimeOfDay? _endZeit;
  String _typ = 'termin';
  String _status = 'geplant';
  String? _kundeId;
  String? _auftragId;

  final Map<String, String> _typLabels = const {
    'termin': 'Termin',
    'auftrag': 'Auftrag',
    'service': 'Service',
    'erinnerung': 'Erinnerung',
  };

  final Map<String, String> _statusLabels = const {
    'geplant': 'Geplant',
    'bestaetigt': 'Bestaetigt',
    'erledigt': 'Erledigt',
    'abgesagt': 'Abgesagt',
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.terminId != null;
    if (_isEdit) {
      _loadTermin();
    }
  }

  Future<void> _loadTermin() async {
    setState(() => _isLoading = true);
    try {
      final termin = await TerminRepository.getById(widget.terminId!);
      if (termin != null && mounted) {
        _existingTermin = termin;
        _titelController.text = termin.titel;
        _beschreibungController.text = termin.beschreibung ?? '';
        _ortController.text = termin.ort ?? '';
        _notizenController.text = ''; // Termin model has no notizen field on its own
        _datum = termin.datum;
        _ganztaegig = termin.ganztaegig;
        _typ = termin.typ;
        _status = termin.status;
        _kundeId = termin.kundeId;
        _auftragId = termin.auftragId;

        if (termin.startZeit != null) {
          final parts = termin.startZeit!.split(':');
          if (parts.length >= 2) {
            _startZeit = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
        if (termin.endZeit != null) {
          final parts = termin.endZeit!.split(':');
          if (parts.length >= 2) {
            _endZeit = TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 0,
              minute: int.tryParse(parts[1]) ?? 0,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDatum() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      locale: const Locale('de', 'CH'),
      useRootNavigator: false,
    );
    if (picked != null && mounted) {
      setState(() => _datum = picked);
    }
  }

  Future<void> _pickStartZeit() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startZeit ?? const TimeOfDay(hour: 8, minute: 0),
      useRootNavigator: false,
    );
    if (picked != null && mounted) {
      setState(() => _startZeit = picked);
    }
  }

  Future<void> _pickEndZeit() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endZeit ?? _startZeit ?? const TimeOfDay(hour: 9, minute: 0),
      useRootNavigator: false,
    );
    if (picked != null && mounted) {
      setState(() => _endZeit = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = await BetriebService.getDataOwnerId();

      final termin = Termin(
        id: _isEdit ? _existingTermin!.id : const Uuid().v4(),
        userId: _isEdit ? _existingTermin!.userId : userId,
        titel: _titelController.text.trim(),
        beschreibung: _beschreibungController.text.trim().isEmpty
            ? null
            : _beschreibungController.text.trim(),
        datum: _datum,
        ganztaegig: _ganztaegig,
        startZeit: _ganztaegig ? null : _formatTimeOfDay(_startZeit),
        endZeit: _ganztaegig ? null : _formatTimeOfDay(_endZeit),
        ort: _ortController.text.trim().isEmpty
            ? null
            : _ortController.text.trim(),
        kundeId: _kundeId,
        auftragId: _auftragId,
        typ: _typ,
        status: _status,
      );

      await TerminRepository.save(termin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Termin aktualisiert' : 'Termin erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        // Invalidate relevant providers
        ref.invalidate(termineByMonatProvider(_datum));
        ref.invalidate(termineByDatumProvider(_datum));
        ref.invalidate(termineHeuteCountProvider);
        if (_isEdit) {
          ref.invalidate(terminProvider(widget.terminId!));
        }
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin loeschen?'),
        content: const Text(
          'Moechtest du diesen Termin wirklich loeschen? '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppStatusColors.error,
            ),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isLoading = true);
      try {
        await TerminRepository.delete(widget.terminId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Termin geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          ref.invalidate(termineByMonatProvider(_datum));
          ref.invalidate(termineByDatumProvider(_datum));
          ref.invalidate(termineHeuteCountProvider);
          ref.invalidate(terminProvider(widget.terminId!));
          if (Navigator.canPop(context)) {
            context.pop();
          } else {
            context.go('/kalender');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Loeschen: $e'),
              backgroundColor: AppStatusColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _titelController.dispose();
    _beschreibungController.dispose();
    _ortController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final kundenAsync = ref.watch(kundenListProvider);
    final auftraegeAsync = ref.watch(auftraegeListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/kalender'),
        ),
        title: Text(_isEdit ? 'Termin bearbeiten' : 'Neuer Termin'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppStatusColors.error,
              onPressed: _isLoading ? null : _confirmDelete,
              tooltip: 'Loeschen',
            ),
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check),
            label: const Text('Speichern'),
          ),
        ],
      ),
      body: _isLoading && _isEdit && _existingTermin == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Titel ───
                    TextFormField(
                      controller: _titelController,
                      decoration: const InputDecoration(
                        labelText: 'Titel *',
                        prefixIcon: Icon(Icons.title),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pflichtfeld';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Beschreibung ───
                    TextFormField(
                      controller: _beschreibungController,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      minLines: 2,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 24),

                    // ─── Datum & Zeit ───
                    _sectionHeader('DATUM & ZEIT'),
                    const SizedBox(height: 12),

                    // Datum
                    InkWell(
                      onTap: _pickDatum,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Datum *',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        child: Text(
                          _dateFormat.format(_datum),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ganztaegig Toggle
                    SwitchListTile(
                      title: const Text('Ganztaegig'),
                      subtitle: const Text('Keine Start-/Endzeit'),
                      value: _ganztaegig,
                      onChanged: (value) {
                        setState(() {
                          _ganztaegig = value;
                          if (value) {
                            _startZeit = null;
                            _endZeit = null;
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Start-/Endzeit (nur wenn nicht ganztaegig)
                    if (!_ganztaegig) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickStartZeit,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Startzeit',
                                  prefixIcon:
                                      Icon(Icons.access_time_outlined),
                                ),
                                child: Text(
                                  _startZeit != null
                                      ? _formatTimeOfDay(_startZeit)
                                      : '--:--',
                                  style: TextStyle(
                                    color: _startZeit != null
                                        ? null
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickEndZeit,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Endzeit',
                                  prefixIcon:
                                      Icon(Icons.access_time_filled),
                                ),
                                child: Text(
                                  _endZeit != null
                                      ? _formatTimeOfDay(_endZeit)
                                      : '--:--',
                                  style: TextStyle(
                                    color: _endZeit != null
                                        ? null
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ─── Ort ───
                    TextFormField(
                      controller: _ortController,
                      decoration: const InputDecoration(
                        labelText: 'Ort',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        hintText: 'z.B. Werkstatt, Baustelle, Buero',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),

                    // ─── Klassifizierung ───
                    _sectionHeader('KLASSIFIZIERUNG'),
                    const SizedBox(height: 12),

                    // Typ Dropdown
                    DropdownButtonFormField<String>(
                      value: _typ,
                      decoration: const InputDecoration(
                        labelText: 'Typ',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: _typLabels.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _typ = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown (nur im Bearbeitungsmodus)
                    if (_isEdit)
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: _statusLabels.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _statusColor(entry.key),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(entry.value),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Verknuepfungen ───
                    _sectionHeader('VERKNUEPFUNGEN'),
                    const SizedBox(height: 12),

                    // Kunde Dropdown
                    kundenAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Fehler: $e'),
                      data: (kunden) {
                        return DropdownButtonFormField<String?>(
                          value: _kundeId,
                          decoration: const InputDecoration(
                            labelText: 'Kunde (optional)',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Kein Kunde'),
                            ),
                            ...kunden.map((k) {
                              final name = k.firma ??
                                  '${k.vorname ?? ''} ${k.nachname}'
                                      .trim();
                              return DropdownMenuItem<String?>(
                                value: k.serverId ?? k.id.toString(),
                                child: Text(
                                  name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _kundeId = value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Auftrag Dropdown
                    auftraegeAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Fehler: $e'),
                      data: (auftraege) {
                        return DropdownButtonFormField<String?>(
                          value: _auftragId,
                          decoration: const InputDecoration(
                            labelText: 'Auftrag (optional)',
                            prefixIcon: Icon(Icons.work_outline),
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Kein Auftrag'),
                            ),
                            ...auftraege.map((a) {
                              final label = a.auftragsNr ?? a.serverId ?? 'Auftrag';
                              return DropdownMenuItem<String?>(
                                value: a.serverId ?? a.id.toString(),
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _auftragId = value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Notizen ───
                    _sectionHeader('NOTIZEN'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _notizenController,
                      decoration: const InputDecoration(
                        labelText: 'Notizen',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      minLines: 2,
                      textInputAction: TextInputAction.newline,
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'geplant':
        return AppStatusColors.offen;
      case 'bestaetigt':
        return AppStatusColors.info;
      case 'erledigt':
        return AppStatusColors.abgeschlossen;
      case 'abgesagt':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }
}
