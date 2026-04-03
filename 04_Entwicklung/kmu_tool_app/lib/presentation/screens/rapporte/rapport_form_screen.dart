import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/rapport_local_export.dart';
import 'package:kmu_tool_app/data/repositories/rapport_repository.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class RapportFormScreen extends StatefulWidget {
  final String auftragId;

  const RapportFormScreen({super.key, required this.auftragId});

  @override
  State<RapportFormScreen> createState() => _RapportFormScreenState();
}

class _RapportFormScreenState extends State<RapportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _beschreibungController = TextEditingController();

  DateTime _datum = DateTime.now();
  String _status = 'entwurf';
  bool _isSaving = false;

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');

  @override
  void dispose() {
    _beschreibungController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final rapport = RapportLocal();
      rapport.serverId = const Uuid().v4();
      rapport.userId = SupabaseService.currentUser!.id;
      rapport.auftragId = widget.auftragId;
      rapport.datum = _datum;
      rapport.beschreibung = _beschreibungController.text.trim();
      rapport.status = _status;

      await RapportRepository.save(rapport);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rapport gespeichert'),
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
        title: const Text('Arbeitsrapport'),
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

              // ─── Beschreibung ───
              _SectionLabel(label: 'Beschreibung'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _beschreibungController,
                maxLines: 5,
                minLines: 3,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(Icons.description_outlined),
                  ),
                  hintText: 'Beschreibung der ausgeführten Arbeiten...',
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Beschreibung ist erforderlich';
                  }
                  if (value.trim().length < 5) {
                    return 'Mindestens 5 Zeichen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ─── Status ───
              _SectionLabel(label: 'Status'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'entwurf',
                    label: Text('Entwurf'),
                    icon: Icon(Icons.edit_outlined),
                  ),
                  ButtonSegment(
                    value: 'abgeschlossen',
                    label: Text('Abgeschlossen'),
                    icon: Icon(Icons.check_circle_outlined),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (selected) {
                  setState(() => _status = selected.first);
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
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
