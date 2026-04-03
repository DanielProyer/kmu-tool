import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/fahrzeug.dart';
import 'package:kmu_tool_app/data/repositories/fahrzeug_repository.dart';
import 'package:kmu_tool_app/presentation/providers/fahrzeug_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

class FahrzeugFormScreen extends ConsumerStatefulWidget {
  final String? fahrzeugId;

  const FahrzeugFormScreen({super.key, this.fahrzeugId});

  @override
  ConsumerState<FahrzeugFormScreen> createState() =>
      _FahrzeugFormScreenState();
}

class _FahrzeugFormScreenState extends ConsumerState<FahrzeugFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bezeichnungController = TextEditingController();
  final _kennzeichenController = TextEditingController();
  final _markeController = TextEditingController();
  final _modellController = TextEditingController();
  final _jahrgangController = TextEditingController();
  final _kmStandController = TextEditingController();
  final _versicherungController = TextEditingController();
  final _notizenController = TextEditingController();

  DateTime? _naechsteService;
  DateTime? _naechsteMfk;
  bool _aktiv = true;
  bool _isLoading = false;
  bool _isEdit = false;
  Fahrzeug? _existingFahrzeug;

  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _isEdit = widget.fahrzeugId != null;
    if (_isEdit) {
      _loadFahrzeug();
    }
  }

  Future<void> _loadFahrzeug() async {
    setState(() => _isLoading = true);
    try {
      final fahrzeug = await FahrzeugRepository.getById(widget.fahrzeugId!);
      if (fahrzeug != null && mounted) {
        _existingFahrzeug = fahrzeug;
        _bezeichnungController.text = fahrzeug.bezeichnung;
        _kennzeichenController.text = fahrzeug.kennzeichen ?? '';
        _markeController.text = fahrzeug.marke ?? '';
        _modellController.text = fahrzeug.modell ?? '';
        _jahrgangController.text =
            fahrzeug.jahrgang != null ? fahrzeug.jahrgang.toString() : '';
        _kmStandController.text =
            fahrzeug.kmStand != null ? fahrzeug.kmStand.toString() : '';
        _versicherungController.text = fahrzeug.versicherung ?? '';
        _notizenController.text = fahrzeug.notizen ?? '';
        _naechsteService = fahrzeug.naechsteService;
        _naechsteMfk = fahrzeug.naechsteMfk;
        _aktiv = fahrzeug.aktiv;
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

  Future<void> _pickDate({
    required DateTime? currentValue,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('de', 'CH'),
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _isEdit
          ? _existingFahrzeug!.userId
          : await BetriebService.getDataOwnerId();

      final fahrzeug = Fahrzeug(
        id: _isEdit ? _existingFahrzeug!.id : const Uuid().v4(),
        userId: userId,
        bezeichnung: _bezeichnungController.text.trim(),
        kennzeichen: _kennzeichenController.text.trim().isEmpty
            ? null
            : _kennzeichenController.text.trim(),
        marke: _markeController.text.trim().isEmpty
            ? null
            : _markeController.text.trim(),
        modell: _modellController.text.trim().isEmpty
            ? null
            : _modellController.text.trim(),
        jahrgang: int.tryParse(_jahrgangController.text.trim()),
        naechsteService: _naechsteService,
        naechsteMfk: _naechsteMfk,
        kmStand: int.tryParse(_kmStandController.text.trim()),
        versicherung: _versicherungController.text.trim().isEmpty
            ? null
            : _versicherungController.text.trim(),
        notizen: _notizenController.text.trim().isEmpty
            ? null
            : _notizenController.text.trim(),
        aktiv: _aktiv,
      );

      await FahrzeugRepository.save(fahrzeug);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Fahrzeug aktualisiert' : 'Fahrzeug erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(fahrzeugeListProvider);
        if (_isEdit) {
          ref.invalidate(fahrzeugProvider(widget.fahrzeugId!));
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
        title: const Text('Fahrzeug loeschen?'),
        content: const Text(
          'Moechtest du dieses Fahrzeug wirklich loeschen? '
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
        await FahrzeugRepository.delete(widget.fahrzeugId!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Fahrzeug geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          ref.invalidate(fahrzeugeListProvider);
          ref.invalidate(fahrzeugProvider(widget.fahrzeugId!));
          if (Navigator.canPop(context)) {
            context.pop();
          } else {
            context.go('/einstellungen/fahrzeuge');
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
    _bezeichnungController.dispose();
    _kennzeichenController.dispose();
    _markeController.dispose();
    _modellController.dispose();
    _jahrgangController.dispose();
    _kmStandController.dispose();
    _versicherungController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/einstellungen/fahrzeuge'),
        ),
        title: Text(
            _isEdit ? 'Fahrzeug bearbeiten' : 'Neues Fahrzeug'),
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
      body: _isLoading && _isEdit && _existingFahrzeug == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Fahrzeugdaten ---
                    _sectionHeader('FAHRZEUGDATEN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bezeichnungController,
                      decoration: const InputDecoration(
                        labelText: 'Bezeichnung *',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                        hintText: 'z.B. Firmenbus, Lieferwagen',
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
                    TextFormField(
                      controller: _kennzeichenController,
                      decoration: const InputDecoration(
                        labelText: 'Kennzeichen',
                        prefixIcon: Icon(Icons.confirmation_number_outlined),
                        hintText: 'z.B. ZH 123456',
                      ),
                      textCapitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _markeController,
                      decoration: const InputDecoration(
                        labelText: 'Marke',
                        prefixIcon: Icon(Icons.branding_watermark_outlined),
                        hintText: 'z.B. VW, Mercedes, Renault',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _modellController,
                      decoration: const InputDecoration(
                        labelText: 'Modell',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                        hintText: 'z.B. Transporter, Sprinter',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _jahrgangController,
                      decoration: const InputDecoration(
                        labelText: 'Jahrgang',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        hintText: 'z.B. 2022',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null ||
                              parsed < 1900 ||
                              parsed > 2100) {
                            return 'Bitte ein gueltiges Jahr eingeben';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- Termine ---
                    _sectionHeader('TERMINE'),
                    const SizedBox(height: 12),
                    _dateField(
                      label: 'Naechster Service',
                      icon: Icons.build_outlined,
                      value: _naechsteService,
                      onTap: () => _pickDate(
                        currentValue: _naechsteService,
                        onPicked: (date) =>
                            setState(() => _naechsteService = date),
                      ),
                      onClear: () =>
                          setState(() => _naechsteService = null),
                    ),
                    const SizedBox(height: 16),
                    _dateField(
                      label: 'Naechste MFK',
                      icon: Icons.verified_outlined,
                      value: _naechsteMfk,
                      onTap: () => _pickDate(
                        currentValue: _naechsteMfk,
                        onPicked: (date) =>
                            setState(() => _naechsteMfk = date),
                      ),
                      onClear: () =>
                          setState(() => _naechsteMfk = null),
                    ),
                    const SizedBox(height: 24),

                    // --- Weitere Angaben ---
                    _sectionHeader('WEITERE ANGABEN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _kmStandController,
                      decoration: const InputDecoration(
                        labelText: 'KM-Stand',
                        prefixIcon: Icon(Icons.speed_outlined),
                        suffixText: 'km',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Bitte eine gueltige Zahl eingeben';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _versicherungController,
                      decoration: const InputDecoration(
                        labelText: 'Versicherung',
                        prefixIcon: Icon(Icons.shield_outlined),
                        hintText: 'z.B. Zurich, Mobiliar',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Aktiv'),
                      subtitle: Text(
                        _aktiv ? 'Fahrzeug ist in Betrieb' : 'Fahrzeug ist ausser Betrieb',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      value: _aktiv,
                      onChanged: (value) {
                        setState(() => _aktiv = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // --- Notizen ---
                    _sectionHeader('NOTIZEN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notizenController,
                      decoration: const InputDecoration(
                        labelText: 'Allgemeine Notizen',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      minLines: 3,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _dateField({
    required String label,
    required IconData icon,
    required DateTime? value,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                )
              : null,
        ),
        child: Text(
          value != null ? _dateFormat.format(value) : 'Datum waehlen...',
          style: TextStyle(
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
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
}
