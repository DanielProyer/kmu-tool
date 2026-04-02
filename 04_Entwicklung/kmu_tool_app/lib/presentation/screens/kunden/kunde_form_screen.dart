import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/core/validators/validators.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/plz/plz_service.dart';

class KundeFormScreen extends ConsumerStatefulWidget {
  final String? kundeId;

  const KundeFormScreen({super.key, this.kundeId});

  @override
  ConsumerState<KundeFormScreen> createState() => _KundeFormScreenState();
}

class _KundeFormScreenState extends ConsumerState<KundeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firmaController = TextEditingController();
  final _vornameController = TextEditingController();
  final _nachnameController = TextEditingController();
  final _strasseController = TextEditingController();
  final _plzController = TextEditingController();
  final _ortController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _notizenController = TextEditingController();

  // Rechnungsadresse
  bool _reAbweichend = false;
  final _reFirmaController = TextEditingController();
  final _reVornameController = TextEditingController();
  final _reNachnameController = TextEditingController();
  final _reStrasseController = TextEditingController();
  final _rePlzController = TextEditingController();
  final _reOrtController = TextEditingController();
  final _reEmailController = TextEditingController();

  String _rechnungsstellung = 'email';

  bool _isLoading = false;
  bool _isEdit = false;
  KundeLocal? _existingKunde;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.kundeId != null;
    if (_isEdit) {
      _loadKunde();
    }

    // PLZ → Ort Auto-Fill
    _plzController.addListener(_onPlzChanged);
    _rePlzController.addListener(_onRePlzChanged);
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

  void _onRePlzChanged() {
    final plz = _rePlzController.text.trim();
    if (plz.length == 4 && _reOrtController.text.isEmpty) {
      final ort = PlzService.getOrt(plz);
      if (ort != null) {
        _reOrtController.text = ort;
      }
    }
  }

  Future<void> _loadKunde() async {
    setState(() => _isLoading = true);
    try {
      final kunde = await KundeRepository.getById(widget.kundeId!);
      if (kunde != null && mounted) {
        _existingKunde = kunde;
        _firmaController.text = kunde.firma ?? '';
        _vornameController.text = kunde.vorname ?? '';
        _nachnameController.text = kunde.nachname;
        _strasseController.text = kunde.strasse ?? '';
        _plzController.text = kunde.plz ?? '';
        _ortController.text = kunde.ort ?? '';
        _telefonController.text = kunde.telefon ?? '';
        _emailController.text = kunde.email ?? '';
        _notizenController.text = kunde.notizen ?? '';
        _reAbweichend = kunde.reAbweichend;
        _reFirmaController.text = kunde.reFirma ?? '';
        _reVornameController.text = kunde.reVorname ?? '';
        _reNachnameController.text = kunde.reNachname ?? '';
        _reStrasseController.text = kunde.reStrasse ?? '';
        _rePlzController.text = kunde.rePlz ?? '';
        _reOrtController.text = kunde.reOrt ?? '';
        _reEmailController.text = kunde.reEmail ?? '';
        _rechnungsstellung = kunde.rechnungsstellung;
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
      final kunde = _existingKunde ?? KundeLocal();

      if (!_isEdit) {
        kunde.serverId = const Uuid().v4();
      }

      kunde.firma = _firmaController.text.trim().isEmpty
          ? null
          : _firmaController.text.trim();
      kunde.vorname = _vornameController.text.trim().isEmpty
          ? null
          : _vornameController.text.trim();
      kunde.nachname = _nachnameController.text.trim();
      kunde.strasse = _strasseController.text.trim().isEmpty
          ? null
          : _strasseController.text.trim();
      kunde.plz = _plzController.text.trim().isEmpty
          ? null
          : _plzController.text.trim();
      kunde.ort = _ortController.text.trim().isEmpty
          ? null
          : _ortController.text.trim();
      kunde.telefon = _telefonController.text.trim().isEmpty
          ? null
          : PhoneValidator.format(_telefonController.text.trim());
      kunde.email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();
      kunde.notizen = _notizenController.text.trim().isEmpty
          ? null
          : _notizenController.text.trim();

      // Rechnungsadresse
      kunde.reAbweichend = _reAbweichend;
      if (_reAbweichend) {
        kunde.reFirma = _reFirmaController.text.trim().isEmpty
            ? null : _reFirmaController.text.trim();
        kunde.reVorname = _reVornameController.text.trim().isEmpty
            ? null : _reVornameController.text.trim();
        kunde.reNachname = _reNachnameController.text.trim().isEmpty
            ? null : _reNachnameController.text.trim();
        kunde.reStrasse = _reStrasseController.text.trim().isEmpty
            ? null : _reStrasseController.text.trim();
        kunde.rePlz = _rePlzController.text.trim().isEmpty
            ? null : _rePlzController.text.trim();
        kunde.reOrt = _reOrtController.text.trim().isEmpty
            ? null : _reOrtController.text.trim();
        kunde.reEmail = _reEmailController.text.trim().isEmpty
            ? null : _reEmailController.text.trim();
      } else {
        kunde.reFirma = null;
        kunde.reVorname = null;
        kunde.reNachname = null;
        kunde.reStrasse = null;
        kunde.rePlz = null;
        kunde.reOrt = null;
        kunde.reEmail = null;
      }
      kunde.rechnungsstellung = _rechnungsstellung;

      await KundeRepository.save(kunde);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEdit ? 'Kunde aktualisiert' : 'Kunde erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(kundenListProvider);
        if (_isEdit) {
          ref.invalidate(kundeProvider(widget.kundeId!));
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
    _rePlzController.removeListener(_onRePlzChanged);
    _firmaController.dispose();
    _vornameController.dispose();
    _nachnameController.dispose();
    _strasseController.dispose();
    _plzController.dispose();
    _ortController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _notizenController.dispose();
    _reFirmaController.dispose();
    _reVornameController.dispose();
    _reNachnameController.dispose();
    _reStrasseController.dispose();
    _rePlzController.dispose();
    _reOrtController.dispose();
    _reEmailController.dispose();
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
              : context.go('/kunden'),
        ),
        title: Text(_isEdit ? 'Kunde bearbeiten' : 'Neuer Kunde'),
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
      body: _isLoading && _isEdit && _existingKunde == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Firma (optional) ───
                    TextFormField(
                      controller: _firmaController,
                      decoration: const InputDecoration(
                        labelText: 'Firma (optional)',
                        prefixIcon: Icon(Icons.business),
                        hintText: 'Leer lassen fuer Privatkunden',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ─── Vorname / Nachname ───
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _vornameController,
                            decoration: const InputDecoration(
                              labelText: 'Vorname',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nachnameController,
                            decoration: const InputDecoration(
                              labelText: 'Nachname *',
                            ),
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Pflichtfeld';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Adresse ───
                    _sectionHeader('ADRESSE'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _strasseController,
                      decoration: const InputDecoration(
                        labelText: 'Strasse',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      textInputAction: TextInputAction.next,
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

                    // ─── Kontakt ───
                    _sectionHeader('KONTAKT'),
                    const SizedBox(height: 12),
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

                    // ─── Rechnungsstellung ───
                    _sectionHeader('RECHNUNGSSTELLUNG'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _rechnungsstellung,
                      decoration: const InputDecoration(
                        labelText: 'Art der Rechnungsstellung',
                        prefixIcon: Icon(Icons.receipt_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'email', child: Text('Per E-Mail')),
                        DropdownMenuItem(
                            value: 'post', child: Text('Per Post')),
                        DropdownMenuItem(
                            value: 'bar', child: Text('Barzahler')),
                        DropdownMenuItem(
                            value: 'abgabe_vor_ort',
                            child: Text('Abgabe vor Ort')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _rechnungsstellung = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Abweichende Rechnungsadresse
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Abweichende Rechnungsadresse'),
                      value: _reAbweichend,
                      onChanged: (value) =>
                          setState(() => _reAbweichend = value),
                    ),
                    if (_reAbweichend) ...[
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reFirmaController,
                        decoration: const InputDecoration(
                          labelText: 'Firma (Rechnung)',
                          prefixIcon: Icon(Icons.business),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _reVornameController,
                              decoration: const InputDecoration(
                                labelText: 'Vorname',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _reNachnameController,
                              decoration: const InputDecoration(
                                labelText: 'Nachname',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reStrasseController,
                        decoration: const InputDecoration(
                          labelText: 'Strasse',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: TextFormField(
                              controller: _rePlzController,
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
                              controller: _reOrtController,
                              decoration: const InputDecoration(
                                labelText: 'Ort',
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _reEmailController,
                        decoration: const InputDecoration(
                          labelText: 'E-Mail (Rechnung)',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: EmailValidator.validate,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ─── Notizen (mehrzeilig) ───
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
