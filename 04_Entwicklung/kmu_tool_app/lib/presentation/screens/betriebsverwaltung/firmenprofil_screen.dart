import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/core/validators/validators.dart';
import 'package:kmu_tool_app/data/repositories/user_profile_repository.dart';
import 'package:kmu_tool_app/services/plz/plz_service.dart';

class FirmenprofilScreen extends ConsumerStatefulWidget {
  const FirmenprofilScreen({super.key});

  @override
  ConsumerState<FirmenprofilScreen> createState() => _FirmenprofilScreenState();
}

class _FirmenprofilScreenState extends ConsumerState<FirmenprofilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firmaNameController = TextEditingController();
  final _strasseController = TextEditingController();
  final _hausnummerController = TextEditingController();
  final _plzController = TextEditingController();
  final _ortController = TextEditingController();
  final _telefonController = TextEditingController();
  final _uidNummerController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _plzController.addListener(_onPlzChanged);
    _loadProfile();
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

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await UserProfileRepository.getCurrentProfile();
      if (profile != null && mounted) {
        _firmaNameController.text = profile.firmaName;
        _strasseController.text = profile.strasse ?? '';
        _hausnummerController.text = profile.hausnummer ?? '';
        _plzController.text = profile.plz ?? '';
        _ortController.text = profile.ort ?? '';
        _telefonController.text = profile.telefon ?? '';
        _uidNummerController.text = profile.uidNummer ?? '';
        _websiteUrlController.text = profile.websiteUrl ?? '';
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
      await UserProfileRepository.updateFields({
        'firma_name': _firmaNameController.text.trim(),
        'strasse': _strasseController.text.trim().isEmpty
            ? null
            : _strasseController.text.trim(),
        'hausnummer': _hausnummerController.text.trim().isEmpty
            ? null
            : _hausnummerController.text.trim(),
        'plz': _plzController.text.trim().isEmpty
            ? null
            : _plzController.text.trim(),
        'ort': _ortController.text.trim().isEmpty
            ? null
            : _ortController.text.trim(),
        'telefon': _telefonController.text.trim().isEmpty
            ? null
            : PhoneValidator.format(_telefonController.text.trim()),
        'uid_nummer': _uidNummerController.text.trim().isEmpty
            ? null
            : _uidNummerController.text.trim(),
        'website_url': _websiteUrlController.text.trim().isEmpty
            ? null
            : _websiteUrlController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Firmenprofil gespeichert'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
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
    _firmaNameController.dispose();
    _strasseController.dispose();
    _hausnummerController.dispose();
    _plzController.dispose();
    _ortController.dispose();
    _telefonController.dispose();
    _uidNummerController.dispose();
    _websiteUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmenprofil'),
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
      body: _isLoading && _firmaNameController.text.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('FIRMA'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _firmaNameController,
                      decoration: const InputDecoration(
                        labelText: 'Firmenname *',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _uidNummerController,
                      decoration: const InputDecoration(
                        labelText: 'UID-Nummer',
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'CHE-123.456.789',
                      ),
                    ),
                    const SizedBox(height: 24),

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
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: _hausnummerController,
                            decoration: const InputDecoration(labelText: 'Nr.'),
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
                            decoration: const InputDecoration(labelText: 'PLZ'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _ortController,
                            decoration: const InputDecoration(labelText: 'Ort'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

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
                      validator: PhoneValidator.validate,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _websiteUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        prefixIcon: Icon(Icons.language),
                        hintText: 'www.meine-firma.ch',
                      ),
                      keyboardType: TextInputType.url,
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
