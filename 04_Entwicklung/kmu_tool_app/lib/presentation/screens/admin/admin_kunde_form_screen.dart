import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/admin/admin_kundenprofil.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_kundenprofil_repository.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';

class AdminKundeFormScreen extends ConsumerStatefulWidget {
  final String? kundeProfilId;

  const AdminKundeFormScreen({super.key, this.kundeProfilId});

  @override
  ConsumerState<AdminKundeFormScreen> createState() =>
      _AdminKundeFormScreenState();
}

class _AdminKundeFormScreenState
    extends ConsumerState<AdminKundeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Firma
  final _firmaNameController = TextEditingController();
  final _kontaktpersonController = TextEditingController();
  final _brancheController = TextEditingController();

  // Kontakt
  final _emailController = TextEditingController();
  final _telefonController = TextEditingController();

  // Adresse
  final _strasseController = TextEditingController();
  final _hausnummerController = TextEditingController();
  final _plzController = TextEditingController();
  final _ortController = TextEditingController();

  // Voreinstellungen
  String _mwstMethode = 'effektiv';
  final _anzahlMitarbeiterController = TextEditingController(text: '1');
  final _anzahlFahrzeugeController = TextEditingController(text: '0');

  // Status
  String _status = 'aktiv';

  // Notizen
  final _notizenController = TextEditingController();

  bool _isLoading = false;
  bool _isEdit = false;
  AdminKundenprofil? _existing;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.kundeProfilId != null;
    if (_isEdit) {
      _loadKunde();
    }
  }

  Future<void> _loadKunde() async {
    setState(() => _isLoading = true);
    try {
      final profil =
          await AdminKundenprofilRepository.getById(widget.kundeProfilId!);
      if (profil != null && mounted) {
        _existing = profil;
        _firmaNameController.text = profil.firmaName;
        _kontaktpersonController.text = profil.kontaktperson ?? '';
        _brancheController.text = profil.branche ?? '';
        _emailController.text = profil.email ?? '';
        _telefonController.text = profil.telefon ?? '';
        _strasseController.text = profil.strasse ?? '';
        _hausnummerController.text = profil.hausnummer ?? '';
        _plzController.text = profil.plz ?? '';
        _ortController.text = profil.ort ?? '';
        _mwstMethode = profil.mwstMethode;
        _anzahlMitarbeiterController.text =
            profil.anzahlMitarbeiter.toString();
        _anzahlFahrzeugeController.text =
            profil.anzahlFahrzeuge.toString();
        _status = profil.status;
        _notizenController.text = profil.notizen ?? '';
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
      final id = _isEdit ? widget.kundeProfilId! : const Uuid().v4();

      final profil = AdminKundenprofil(
        id: id,
        userId: _existing?.userId,
        firmaName: _firmaNameController.text.trim(),
        kontaktperson: _kontaktpersonController.text.trim().isEmpty
            ? null
            : _kontaktpersonController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        telefon: _telefonController.text.trim().isEmpty
            ? null
            : _telefonController.text.trim(),
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
        status: _status,
        mwstMethode: _mwstMethode,
        anzahlMitarbeiter:
            int.tryParse(_anzahlMitarbeiterController.text.trim()) ?? 1,
        anzahlFahrzeuge:
            int.tryParse(_anzahlFahrzeugeController.text.trim()) ?? 0,
        branche: _brancheController.text.trim().isEmpty
            ? null
            : _brancheController.text.trim(),
        notizen: _notizenController.text.trim().isEmpty
            ? null
            : _notizenController.text.trim(),
        registriertAm: _existing?.registriertAm ?? DateTime.now(),
        createdAt: _existing?.createdAt,
        updatedAt: _existing?.updatedAt,
        planId: _existing?.planId,
        planBezeichnung: _existing?.planBezeichnung,
      );

      await AdminKundenprofilRepository.save(profil);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Kunde aktualisiert' : 'Kunde erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(adminKundenListProvider);
        if (_isEdit) {
          ref.invalidate(
              adminKundeProvider(widget.kundeProfilId!));
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
    _firmaNameController.dispose();
    _kontaktpersonController.dispose();
    _brancheController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _strasseController.dispose();
    _hausnummerController.dispose();
    _plzController.dispose();
    _ortController.dispose();
    _anzahlMitarbeiterController.dispose();
    _anzahlFahrzeugeController.dispose();
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
              : context.go('/admin/kunden'),
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
      body: _isLoading && _isEdit && _existing == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── FIRMA ───
                    _sectionHeader('FIRMA'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firmaNameController,
                      decoration: const InputDecoration(
                        labelText: 'Firmenname *',
                        prefixIcon: Icon(Icons.business),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Firmenname ist erforderlich';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kontaktpersonController,
                      decoration: const InputDecoration(
                        labelText: 'Kontaktperson',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _brancheController,
                      decoration: const InputDecoration(
                        labelText: 'Branche',
                        prefixIcon: Icon(Icons.work_outline),
                        hintText: 'z.B. Sanitaer, Elektro, Malerei',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),

                    // ─── KONTAKT ───
                    _sectionHeader('KONTAKT'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        prefixIcon: Icon(Icons.email_outlined),
                        hintText: 'info@firma.ch',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                    ),
                    const SizedBox(height: 24),

                    // ─── ADRESSE ───
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

                    // ─── VOREINSTELLUNGEN ───
                    _sectionHeader('VOREINSTELLUNGEN'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _mwstMethode,
                      decoration: const InputDecoration(
                        labelText: 'MWST-Methode',
                        prefixIcon: Icon(Icons.receipt_long_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'effektiv',
                          child: Text('Effektive Methode'),
                        ),
                        DropdownMenuItem(
                          value: 'saldosteuersatz',
                          child: Text('Saldosteuersatz'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _mwstMethode = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _anzahlMitarbeiterController,
                            decoration: const InputDecoration(
                              labelText: 'Anzahl Mitarbeiter',
                              prefixIcon: Icon(Icons.people_outline),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final n = int.tryParse(value);
                                if (n == null || n < 0) {
                                  return 'Ungueltige Zahl';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _anzahlFahrzeugeController,
                            decoration: const InputDecoration(
                              labelText: 'Anzahl Fahrzeuge',
                              prefixIcon:
                                  Icon(Icons.directions_car_outlined),
                            ),
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final n = int.tryParse(value);
                                if (n == null || n < 0) {
                                  return 'Ungueltige Zahl';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── STATUS ───
                    _sectionHeader('STATUS'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'aktiv',
                          child: Text('Aktiv'),
                        ),
                        DropdownMenuItem(
                          value: 'inaktiv',
                          child: Text('Inaktiv'),
                        ),
                        DropdownMenuItem(
                          value: 'gesperrt',
                          child: Text('Gesperrt'),
                        ),
                        DropdownMenuItem(
                          value: 'test',
                          child: Text('Test'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── NOTIZEN ───
                    _sectionHeader('NOTIZEN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notizenController,
                      decoration: const InputDecoration(
                        labelText: 'Notizen',
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
