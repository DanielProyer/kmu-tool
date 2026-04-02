import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/kunde_kontakt_local_export.dart';
import 'package:kmu_tool_app/data/repositories/kunde_kontakt_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class KundeKontaktFormScreen extends ConsumerStatefulWidget {
  final String kundeId;
  final String? kontaktId;

  const KundeKontaktFormScreen({
    super.key,
    required this.kundeId,
    this.kontaktId,
  });

  @override
  ConsumerState<KundeKontaktFormScreen> createState() =>
      _KundeKontaktFormScreenState();
}

class _KundeKontaktFormScreenState
    extends ConsumerState<KundeKontaktFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vornameController = TextEditingController();
  final _nachnameController = TextEditingController();
  final _funktionController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isEdit = false;
  KundeKontaktLocal? _existingKontakt;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.kontaktId != null;
    if (_isEdit) {
      _loadKontakt();
    }
  }

  Future<void> _loadKontakt() async {
    setState(() => _isLoading = true);
    try {
      final kontakte =
          await KundeKontaktRepository.getByKunde(widget.kundeId);
      final kontakt = kontakte.where((k) {
        return k.routeId == widget.kontaktId;
      }).firstOrNull;

      if (kontakt != null && mounted) {
        _existingKontakt = kontakt;
        _vornameController.text = kontakt.vorname;
        _nachnameController.text = kontakt.nachname;
        _funktionController.text = kontakt.funktion ?? '';
        _telefonController.text = kontakt.telefon ?? '';
        _emailController.text = kontakt.email ?? '';
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
      final kontakt = _existingKontakt ?? KundeKontaktLocal();

      if (!_isEdit) {
        kontakt.serverId = const Uuid().v4();
        kontakt.kundeId = widget.kundeId;
      }

      kontakt.vorname = _vornameController.text.trim();
      kontakt.nachname = _nachnameController.text.trim();
      kontakt.funktion = _funktionController.text.trim().isEmpty
          ? null
          : _funktionController.text.trim();
      kontakt.telefon = _telefonController.text.trim().isEmpty
          ? null
          : _telefonController.text.trim();
      kontakt.email = _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim();

      await KundeKontaktRepository.save(kontakt);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Kontaktperson aktualisiert'
                : 'Kontaktperson hinzugefuegt'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(kundeKontakteProvider(widget.kundeId));
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
    _vornameController.dispose();
    _nachnameController.dispose();
    _funktionController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit
            ? 'Kontaktperson bearbeiten'
            : 'Neue Kontaktperson'),
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
      body: _isLoading && _isEdit && _existingKontakt == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Vorname / Nachname
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
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
                    const SizedBox(height: 16),

                    // Funktion
                    TextFormField(
                      controller: _funktionController,
                      decoration: const InputDecoration(
                        labelText: 'Funktion',
                        prefixIcon: Icon(Icons.work_outline),
                        hintText: 'z.B. Geschaeftsfuehrer, Bauleiter',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Telefon
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

                    // E-Mail
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'name@firma.ch',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
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
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
