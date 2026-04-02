import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: AppColors.error,
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
          : _telefonController.text.trim();
      kunde.email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();
      kunde.notizen = _notizenController.text.trim().isEmpty
          ? null
          : _notizenController.text.trim();

      await KundeRepository.save(kunde);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_isEdit ? 'Kunde aktualisiert' : 'Kunde erstellt'),
            backgroundColor: AppColors.success,
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
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _firmaController.dispose();
    _vornameController.dispose();
    _nachnameController.dispose();
    _strasseController.dispose();
    _plzController.dispose();
    _ortController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                    // ─── Firma ───
                    TextFormField(
                      controller: _firmaController,
                      decoration: const InputDecoration(
                        labelText: 'Firma',
                        prefixIcon: Icon(Icons.business),
                        hintText: 'Optional',
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

                    // ─── Abschnitt: Adresse ───
                    const Text(
                      'ADRESSE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
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

                    // ─── Abschnitt: Kontakt ───
                    const Text(
                      'KONTAKT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
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
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$')
                              .hasMatch(value.trim())) {
                            return 'Ungueltige E-Mail';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Notizen ───
                    const Text(
                      'NOTIZEN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notizenController,
                      decoration: const InputDecoration(
                        labelText: 'Notizen',
                        prefixIcon: Icon(Icons.notes_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
