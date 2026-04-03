import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/core/validators/validators.dart';
import 'package:kmu_tool_app/data/models/mitarbeiter.dart';
import 'package:kmu_tool_app/data/repositories/mitarbeiter_repository.dart';
import 'package:kmu_tool_app/presentation/providers/mitarbeiter_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

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
  final _notizenController = TextEditingController();

  String _rolle = 'mitarbeiter';
  double _pensum = 1.0;
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
    if (_isEdit) {
      _loadMitarbeiter();
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
    _vornameController.dispose();
    _nachnameController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _strasseController.dispose();
    _hausnummerController.dispose();
    _plzController.dispose();
    _ortController.dispose();
    _ahvNummerController.dispose();
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
