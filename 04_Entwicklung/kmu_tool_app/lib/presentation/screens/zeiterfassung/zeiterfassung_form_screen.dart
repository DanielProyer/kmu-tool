import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/zeiterfassung_local_export.dart';
import 'package:kmu_tool_app/data/repositories/zeiterfassung_repository.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

class ZeiterfassungFormScreen extends StatefulWidget {
  final String auftragId;

  const ZeiterfassungFormScreen({super.key, required this.auftragId});

  @override
  State<ZeiterfassungFormScreen> createState() =>
      _ZeiterfassungFormScreenState();
}

class _ZeiterfassungFormScreenState extends State<ZeiterfassungFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _beschreibungController = TextEditingController();
  final _pauseController = TextEditingController(text: '0');

  DateTime _datum = DateTime.now();
  TimeOfDay? _startZeit;
  TimeOfDay? _endZeit;
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');

  @override
  void dispose() {
    _beschreibungController.dispose();
    _pauseController.dispose();
    super.dispose();
  }

  /// Calculates the duration in minutes from start, end and pause.
  int? get _berechnungDauerMinuten {
    if (_startZeit == null || _endZeit == null) return null;
    final startMinutes = _startZeit!.hour * 60 + _startZeit!.minute;
    final endMinutes = _endZeit!.hour * 60 + _endZeit!.minute;
    final pause = int.tryParse(_pauseController.text) ?? 0;
    final dauer = endMinutes - startMinutes - pause;
    return dauer > 0 ? dauer : null;
  }

  String get _dauerAnzeige {
    final dauer = _berechnungDauerMinuten;
    if (dauer == null) return '--:--';
    final h = dauer ~/ 60;
    final m = dauer % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}min';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDatum() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('de', 'CH'),
      useRootNavigator: false,
    );
    if (picked != null) {
      setState(() => _datum = picked);
    }
  }

  Future<void> _pickStartZeit() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startZeit ?? const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _startZeit = picked);
    }
  }

  Future<void> _pickEndZeit() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endZeit ?? TimeOfDay.now(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _endZeit = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startZeit == null || _endZeit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte Start- und End-Zeit angeben'),
          backgroundColor: AppStatusColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final dauer = _berechnungDauerMinuten;
    if (dauer == null || dauer <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'End-Zeit muss nach Start-Zeit liegen (abzüglich Pause)'),
          backgroundColor: AppStatusColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await BetriebService.getDataOwnerId();
      final ze = ZeiterfassungLocal();
      ze.serverId = const Uuid().v4();
      ze.userId = userId;
      ze.auftragId = widget.auftragId;
      ze.datum = _datum;
      ze.startZeit = _formatTimeOfDay(_startZeit!);
      ze.endZeit = _formatTimeOfDay(_endZeit!);
      ze.pauseMinuten = int.tryParse(_pauseController.text) ?? 0;
      ze.dauerMinuten = dauer;
      ze.beschreibung = _beschreibungController.text.trim().isEmpty
          ? null
          : _beschreibungController.text.trim();

      await ZeiterfassungRepository.save(ze);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zeiterfassung gespeichert'),
            backgroundColor: AppStatusColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppStatusColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Zeit erfassen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Datum ───
              _SectionLabel(label: 'Datum'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDatum,
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(_dateFormat.format(_datum)),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Start-Zeit / End-Zeit ───
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: 'Start-Zeit'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickStartZeit,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.play_arrow_outlined),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _startZeit != null
                                  ? _formatTimeOfDay(_startZeit!)
                                  : 'HH:mm',
                              style: TextStyle(
                                color: _startZeit != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(label: 'End-Zeit'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: _pickEndZeit,
                          borderRadius: BorderRadius.circular(10),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.stop_outlined),
                              suffixIcon: Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _endZeit != null
                                  ? _formatTimeOfDay(_endZeit!)
                                  : 'HH:mm',
                              style: TextStyle(
                                color: _endZeit != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Pause (Minuten) ───
              _SectionLabel(label: 'Pause (Minuten)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pauseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.free_breakfast_outlined),
                  hintText: '0',
                  suffixText: 'min',
                ),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final v = int.tryParse(value);
                    if (v == null || v < 0) {
                      return 'Bitte gültige Zahl eingeben';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Berechnete Dauer ───
              _SectionLabel(label: 'Berechnete Dauer'),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Text(
                      _dauerAnzeige,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _berechnungDauerMinuten != null
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── Beschreibung ───
              _SectionLabel(label: 'Beschreibung (optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _beschreibungController,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_outlined),
                  ),
                  hintText: 'Was wurde erledigt?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // ─── Speichern Button ───
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Speichern...' : 'Speichern'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
    );
  }
}
