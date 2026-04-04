import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/core/validators/validators.dart';
import 'package:kmu_tool_app/data/models/mitarbeiter.dart';
import 'package:kmu_tool_app/data/repositories/mitarbeiter_repository.dart';
import 'package:kmu_tool_app/presentation/providers/mitarbeiter_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';
import 'package:kmu_tool_app/services/plz/plz_service.dart';

class MitarbeiterFormScreen extends ConsumerStatefulWidget {
  final String? mitarbeiterId;

  const MitarbeiterFormScreen({super.key, this.mitarbeiterId});

  @override
  ConsumerState<MitarbeiterFormScreen> createState() =>
      _MitarbeiterFormScreenState();
}

class _MitarbeiterFormScreenState extends ConsumerState<MitarbeiterFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vornameController = TextEditingController();
  final _nachnameController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _strasseController = TextEditingController();
  final _hausnummerController = TextEditingController();
  final _plzController = TextEditingController();
  final _ortController = TextEditingController();
  final _ahvNummerController = TextEditingController();
  final _bruttolohnController = TextEditingController();
  final _anzahlKinderController = TextEditingController();
  final _anzahlKinderAusbildungController = TextEditingController();
  final _quellensteuerCodeController = TextEditingController();
  final _quellensteuerSatzController = TextEditingController();
  final _nationalitaetController = TextEditingController();
  final _bewilligungstypController = TextEditingController();
  final _notizenController = TextEditingController();

  String _rolle = 'mitarbeiter';
  double _pensum = 1.0;
  DateTime? _geburtsdatum;
  DateTime? _eintrittsdatum;
  DateTime? _austrittsdatum;
  final _dateFormat = DateFormat('dd.MM.yyyy');
  bool _isLoading = false;
  bool _isEdit = false;
  Mitarbeiter? _existingMitarbeiter;

  static const _rolleOptions = <String, String>{
    'geschaeftsfuehrer': 'Geschaeftsfuehrer/in',
    'vorarbeiter': 'Vorarbeiter/in',
    'geselle': 'Geselle/Gesellin',
    'lehrling': 'Lehrling',
    'mitarbeiter': 'Mitarbeiter/in',
    'buero': 'Buero',
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.mitarbeiterId != null;
    _plzController.addListener(_onPlzChanged);
    if (_isEdit) {
      _loadMitarbeiter();
    }
  }

  void _onPlzChanged() {
    final plz = _plzController.text.trim();
    if (plz.length == 4 && _ortController.text.isEmpty) {
      final ort = PlzService.getOrt(plz);
      if (ort != null) {
        _ortController.text = ort;
      }
    }
  }

  Future<void> _loadMitarbeiter() async {
    setState(() => _isLoading = true);
    try {
      final mitarbeiter =
          await MitarbeiterRepository.getById(widget.mitarbeiterId!);
      if (mitarbeiter != null && mounted) {
        _existingMitarbeiter = mitarbeiter;
        _vornameController.text = mitarbeiter.vorname;
        _nachnameController.text = mitarbeiter.nachname;
        _telefonController.text = mitarbeiter.telefon ?? '';
        _emailController.text = mitarbeiter.email ?? '';
        _strasseController.text = mitarbeiter.strasse ?? '';
        _hausnummerController.text = mitarbeiter.hausnummer ?? '';
        _plzController.text = mitarbeiter.plz ?? '';
        _ortController.text = mitarbeiter.ort ?? '';
        _ahvNummerController.text = mitarbeiter.ahvNummer ?? '';
        _bruttolohnController.text = mitarbeiter.bruttolohnMonat != null
            ? mitarbeiter.bruttolohnMonat!.toStringAsFixed(0)
            : '';
        _geburtsdatum = mitarbeiter.geburtsdatum;
        _eintrittsdatum = mitarbeiter.eintrittsdatum;
        _austrittsdatum = mitarbeiter.austrittsdatum;
        _anzahlKinderController.text =
            mitarbeiter.anzahlKinder > 0 ? '${mitarbeiter.anzahlKinder}' : '';
        _anzahlKinderAusbildungController.text =
            mitarbeiter.anzahlKinderAusbildung > 0
                ? '${mitarbeiter.anzahlKinderAusbildung}'
                : '';
        _quellensteuerCodeController.text =
            mitarbeiter.quellensteuerCode ?? '';
        _quellensteuerSatzController.text =
            mitarbeiter.quellensteuerSatz?.toString() ?? '';
        _nationalitaetController.text = mitarbeiter.nationalitaet ?? '';
        _bewilligungstypController.text = mitarbeiter.bewilligungstyp ?? '';
        _notizenController.text = mitarbeiter.notizen ?? '';
        _rolle = mitarbeiter.rolle;
        _pensum = mitarbeiter.pensum;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userId = _isEdit
          ? _existingMitarbeiter!.userId
          : await BetriebService.getDataOwnerId();

      final mitarbeiter = Mitarbeiter(
        id: _isEdit ? _existingMitarbeiter!.id : const Uuid().v4(),
        userId: userId,
        vorname: _vornameController.text.trim(),
        nachname: _nachnameController.text.trim(),
        telefon: _telefonController.text.trim().isEmpty
            ? null
            : PhoneValidator.format(_telefonController.text.trim()),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        rolle: _rolle,
        strasse: _strasseController.text.trim().isEmpty
            ? null
            : _strasseController.text.trim(),
        hausnummer: _hausnummerController.text.trim().isEmpty
            ? null
            : _hausnummerController.text.trim(),
        plz: _plzController.text.trim().isEmpty
            ? null
            : _plzController.text.trim(),
        ort: _ortController.text.trim().isEmpty
            ? null
            : _ortController.text.trim(),
        ahvNummer: _ahvNummerController.text.trim().isEmpty
            ? null
            : _ahvNummerController.text.trim(),
        pensum: _pensum,
        bruttolohnMonat: _bruttolohnController.text.trim().isEmpty
            ? null
            : double.tryParse(_bruttolohnController.text.trim()),
        geburtsdatum: _geburtsdatum,
        eintrittsdatum: _eintrittsdatum,
        austrittsdatum: _austrittsdatum,
        anzahlKinder:
            int.tryParse(_anzahlKinderController.text.trim()) ?? 0,
        anzahlKinderAusbildung:
            int.tryParse(_anzahlKinderAusbildungController.text.trim()) ?? 0,
        quellensteuerCode: _quellensteuerCodeController.text.trim().isEmpty
            ? null
            : _quellensteuerCodeController.text.trim(),
        quellensteuerSatz: _quellensteuerSatzController.text.trim().isEmpty
            ? null
            : double.tryParse(_quellensteuerSatzController.text.trim()),
        nationalitaet: _nationalitaetController.text.trim().isEmpty
            ? null
            : _nationalitaetController.text.trim(),
        bewilligungstyp: _bewilligungstypController.text.trim().isEmpty
            ? null
            : _bewilligungstypController.text.trim(),
        notizen: _notizenController.text.trim().isEmpty
            ? null
            : _notizenController.text.trim(),
      );

      await MitarbeiterRepository.save(mitarbeiter);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Mitarbeiter aktualisiert' : 'Mitarbeiter erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(mitarbeiterListProvider);
        if (_isEdit) {
          ref.invalidate(mitarbeiterProvider(widget.mitarbeiterId!));
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

  @override
  void dispose() {
    _plzController.removeListener(_onPlzChanged);
    _vornameController.dispose();
    _nachnameController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _strasseController.dispose();
    _hausnummerController.dispose();
    _plzController.dispose();
    _ortController.dispose();
    _ahvNummerController.dispose();
    _bruttolohnController.dispose();
    _anzahlKinderController.dispose();
    _anzahlKinderAusbildungController.dispose();
    _quellensteuerCodeController.dispose();
    _quellensteuerSatzController.dispose();
    _nationalitaetController.dispose();
    _bewilligungstypController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/einstellungen/mitarbeiter'),
        ),
        title: Text(
            _isEdit ? 'Mitarbeiter bearbeiten' : 'Neuer Mitarbeiter'),
        actions: [
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
      body: _isLoading && _isEdit && _existingMitarbeiter == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Persoenliche Daten ---
                    _sectionHeader('PERSOENLICHE DATEN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _vornameController,
                      decoration: const InputDecoration(
                        labelText: 'Vorname *',
                        prefixIcon: Icon(Icons.person_outline),
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
                      controller: _nachnameController,
                      decoration: const InputDecoration(
                        labelText: 'Nachname *',
                        prefixIcon: Icon(Icons.person),
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
                      controller: _telefonController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+41 79 123 45 67',
                      ),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: PhoneValidator.validate,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'name@firma.ch',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: EmailValidator.validate,
                    ),
                    const SizedBox(height: 24),

                    // --- Rolle & Pensum ---
                    _sectionHeader('ROLLE & PENSUM'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _rolle,
                      decoration: const InputDecoration(
                        labelText: 'Rolle',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: _rolleOptions.entries
                          .map((entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _rolle = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            'Pensum: ${(_pensum * 100).round()}%',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                        Slider(
                          value: _pensum,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label: '${(_pensum * 100).round()}%',
                          onChanged: (value) {
                            setState(() => _pensum = value);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Adresse ---
                    _sectionHeader('ADRESSE'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _strasseController,
                            decoration: const InputDecoration(
                              labelText: 'Strasse',
                              prefixIcon: Icon(Icons.location_on_outlined),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _hausnummerController,
                            decoration: const InputDecoration(
                              labelText: 'Nr.',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _plzController,
                            decoration: const InputDecoration(
                              labelText: 'PLZ',
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _ortController,
                            decoration: const InputDecoration(
                              labelText: 'Ort',
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Lohn ---
                    _sectionHeader('LOHN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bruttolohnController,
                      decoration: const InputDecoration(
                        labelText: 'Bruttolohn / Monat',
                        prefixIcon: Icon(Icons.payments_outlined),
                        suffixText: 'CHF',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    _dateField('Geburtsdatum', _geburtsdatum, (date) {
                      setState(() => _geburtsdatum = date);
                    }),
                    const SizedBox(height: 16),
                    _dateField('Eintrittsdatum', _eintrittsdatum, (date) {
                      setState(() => _eintrittsdatum = date);
                    }),
                    const SizedBox(height: 16),
                    _dateField('Austrittsdatum', _austrittsdatum, (date) {
                      setState(() => _austrittsdatum = date);
                    }),
                    const SizedBox(height: 24),

                    // --- Kinder ---
                    _sectionHeader('KINDER (ZULAGEN)'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _anzahlKinderController,
                            decoration: const InputDecoration(
                              labelText: 'Kinder',
                              prefixIcon: Icon(Icons.child_care_outlined),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _anzahlKinderAusbildungController,
                            decoration: const InputDecoration(
                              labelText: 'In Ausbildung',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // --- Sozialversicherung ---
                    _sectionHeader('SOZIALVERSICHERUNG'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ahvNummerController,
                      decoration: const InputDecoration(
                        labelText: 'AHV-Nummer',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                        hintText: '756.1234.5678.97',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nationalitaetController,
                      decoration: const InputDecoration(
                        labelText: 'Nationalitaet',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bewilligungstypController,
                      decoration: const InputDecoration(
                        labelText: 'Bewilligungstyp',
                        prefixIcon: Icon(Icons.card_membership_outlined),
                        hintText: 'B, C, L, etc.',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Quellensteuer ---
                    _sectionHeader('QUELLENSTEUER'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quellensteuerCodeController,
                            decoration: const InputDecoration(
                              labelText: 'QST-Code',
                              hintText: 'z.B. A0, B1, C2',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _quellensteuerSatzController,
                            decoration: const InputDecoration(
                              labelText: 'QST-Satz',
                              suffixText: '%',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                      ],
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

  Widget _dateField(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          useRootNavigator: false,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
          locale: const Locale('de', 'CH'),
        );
        onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        child: Text(
          value != null ? _dateFormat.format(value) : '',
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
