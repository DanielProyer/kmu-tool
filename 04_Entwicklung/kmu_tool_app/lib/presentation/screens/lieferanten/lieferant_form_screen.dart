import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/core/validators/validators.dart';
import 'package:kmu_tool_app/data/models/lieferant.dart';
import 'package:kmu_tool_app/data/repositories/lieferant_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';
import 'package:kmu_tool_app/services/plz/plz_service.dart';

class LieferantFormScreen extends ConsumerStatefulWidget {
  final String? lieferantId;

  const LieferantFormScreen({super.key, this.lieferantId});

  @override
  ConsumerState<LieferantFormScreen> createState() =>
      _LieferantFormScreenState();
}

class _LieferantFormScreenState extends ConsumerState<LieferantFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firmaController = TextEditingController();
  final _kontaktpersonController = TextEditingController();
  final _strasseController = TextEditingController();
  final _hausnummerController = TextEditingController();
  final _plzController = TextEditingController();
  final _ortController = TextEditingController();
  final _telefonController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _zahlungsfristController = TextEditingController(text: '30');
  final _notizenController = TextEditingController();

  bool _isLoading = false;
  bool _isEdit = false;
  Lieferant? _existingLieferant;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.lieferantId != null;
    _plzController.addListener(_onPlzChanged);
    if (_isEdit) {
      _loadLieferant();
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

  Future<void> _loadLieferant() async {
    setState(() => _isLoading = true);
    try {
      final lieferant =
          await LieferantRepository.getById(widget.lieferantId!);
      if (lieferant != null && mounted) {
        _existingLieferant = lieferant;
        _firmaController.text = lieferant.firma;
        _kontaktpersonController.text = lieferant.kontaktperson ?? '';
        _strasseController.text = lieferant.strasse ?? '';
        _hausnummerController.text = lieferant.hausnummer ?? '';
        _plzController.text = lieferant.plz ?? '';
        _ortController.text = lieferant.ort ?? '';
        _telefonController.text = lieferant.telefon ?? '';
        _emailController.text = lieferant.email ?? '';
        _websiteController.text = lieferant.website ?? '';
        _zahlungsfristController.text =
            lieferant.zahlungsfristTage.toString();
        _notizenController.text = lieferant.notizen ?? '';
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
          ? _existingLieferant!.userId
          : await BetriebService.getDataOwnerId();
      final lieferant = Lieferant(
        id: _isEdit ? _existingLieferant!.id : const Uuid().v4(),
        userId: userId,
        firma: _firmaController.text.trim(),
        kontaktperson: _kontaktpersonController.text.trim().isEmpty
            ? null
            : _kontaktpersonController.text.trim(),
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
        telefon: _telefonController.text.trim().isEmpty
            ? null
            : PhoneValidator.format(_telefonController.text.trim()),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        zahlungsfristTage:
            int.tryParse(_zahlungsfristController.text.trim()) ?? 30,
        notizen: _notizenController.text.trim().isEmpty
            ? null
            : _notizenController.text.trim(),
      );

      await LieferantRepository.save(lieferant);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Lieferant aktualisiert' : 'Lieferant erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(lieferantenListProvider);
        if (_isEdit) {
          ref.invalidate(lieferantProvider(widget.lieferantId!));
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
    _firmaController.dispose();
    _kontaktpersonController.dispose();
    _strasseController.dispose();
    _hausnummerController.dispose();
    _plzController.dispose();
    _ortController.dispose();
    _telefonController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _zahlungsfristController.dispose();
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
              : context.go('/lieferanten'),
        ),
        title: Text(
            _isEdit ? 'Lieferant bearbeiten' : 'Neuer Lieferant'),
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
      body: _isLoading && _isEdit && _existingLieferant == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Kontaktdaten ───
                    _sectionHeader('KONTAKTDATEN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firmaController,
                      decoration: const InputDecoration(
                        labelText: 'Firma *',
                        prefixIcon: Icon(Icons.business),
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
                      controller: _kontaktpersonController,
                      decoration: const InputDecoration(
                        labelText: 'Kontaktperson',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _telefonController,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '+41 44 123 45 67',
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
                        hintText: 'info@firma.ch',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        prefixIcon: Icon(Icons.language),
                        hintText: 'www.firma.ch',
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),

                    // ─── Adresse ───
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

                    // ─── Konditionen ───
                    _sectionHeader('KONDITIONEN'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _zahlungsfristController,
                      decoration: const InputDecoration(
                        labelText: 'Zahlungsfrist (Tage)',
                        prefixIcon: Icon(Icons.schedule_outlined),
                        hintText: '30',
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
                    const SizedBox(height: 24),

                    // ─── Notizen ───
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
