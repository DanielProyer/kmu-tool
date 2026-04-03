import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/admin/admin_datenmigration.dart';
import 'package:kmu_tool_app/data/models/admin/admin_kundenprofil.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_datenmigration_repository.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_kundenprofil_repository.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class AdminMigrationFormScreen extends ConsumerStatefulWidget {
  final String? kundeProfilId;

  const AdminMigrationFormScreen({super.key, this.kundeProfilId});

  @override
  ConsumerState<AdminMigrationFormScreen> createState() =>
      _AdminMigrationFormScreenState();
}

class _AdminMigrationFormScreenState
    extends ConsumerState<AdminMigrationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quellBeschreibungController = TextEditingController();
  final _notizenController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingKunden = true;
  List<AdminKundenprofil> _kunden = [];

  String? _selectedKundeId;
  String? _selectedTyp;
  final Set<String> _selectedModule = {};

  static const _typOptions = [
    ('excel', 'Excel-Import'),
    ('papier', 'Papier-Digitalisierung'),
    ('datenbank', 'Datenbank-Migration'),
    ('andere', 'Andere'),
  ];

  static const _moduleOptions = [
    ('kunden', 'Kunden'),
    ('offerten', 'Offerten'),
    ('auftraege', 'Auftraege'),
    ('rechnungen', 'Rechnungen'),
    ('artikel', 'Artikel'),
    ('buchhaltung', 'Buchhaltung'),
    ('lieferanten', 'Lieferanten'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedKundeId = widget.kundeProfilId;
    _loadKunden();
  }

  Future<void> _loadKunden() async {
    try {
      final kunden = await AdminKundenprofilRepository.getAll();
      if (mounted) {
        setState(() {
          _kunden = kunden;
          _isLoadingKunden = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingKunden = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Kunden: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKundeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte einen Kunden auswaehlen'),
          backgroundColor: AppStatusColors.warning,
        ),
      );
      return;
    }

    if (_selectedTyp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte einen Migrationstyp auswaehlen'),
          backgroundColor: AppStatusColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final migration = AdminDatenmigration(
        id: const Uuid().v4(),
        kundeProfilId: _selectedKundeId!,
        typ: _selectedTyp!,
        quellBeschreibung: _quellBeschreibungController.text.trim().isEmpty
            ? null
            : _quellBeschreibungController.text.trim(),
        module: _selectedModule.toList(),
        status: 'geplant',
        fortschritt: 0,
        notizen: _notizenController.text.trim().isEmpty
            ? null
            : _notizenController.text.trim(),
      );

      await AdminDatenmigrationRepository.save(migration);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Migration erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(adminMigrationenListProvider);
        ref.invalidate(adminDashboardProvider);
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
    _quellBeschreibungController.dispose();
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
              : context.go('/admin/migrationen'),
        ),
        title: const Text('Neue Migration'),
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
      body: _isLoadingKunden
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Kunde ──
                    _sectionHeader('KUNDE'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedKundeId,
                      decoration: const InputDecoration(
                        labelText: 'Kunde *',
                        prefixIcon: Icon(Icons.business),
                      ),
                      isExpanded: true,
                      items: _kunden.map((kunde) {
                        return DropdownMenuItem(
                          value: kunde.id,
                          child: Text(
                            kunde.firmaName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedKundeId = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pflichtfeld';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Migrationstyp ──
                    _sectionHeader('MIGRATIONSTYP'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedTyp,
                      decoration: const InputDecoration(
                        labelText: 'Typ *',
                        prefixIcon: Icon(Icons.category),
                      ),
                      isExpanded: true,
                      items: _typOptions.map((option) {
                        final (value, label) = option;
                        return DropdownMenuItem(
                          value: value,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedTyp = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pflichtfeld';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quellBeschreibungController,
                      decoration: const InputDecoration(
                        labelText: 'Quellbeschreibung',
                        prefixIcon: Icon(Icons.source),
                        alignLabelWithHint: true,
                        hintText:
                            'z.B. Excel-Dateien vom alten System, Ordner mit Papierbelegen...',
                      ),
                      maxLines: 4,
                      minLines: 2,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 24),

                    // ── Module ──
                    _sectionHeader('MODULE'),
                    const SizedBox(height: 8),
                    Text(
                      'Welche Daten sollen migriert werden?',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _moduleOptions.map((option) {
                        final (value, label) = option;
                        final isSelected = _selectedModule.contains(value);
                        return FilterChip(
                          label: Text(label),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedModule.add(value);
                              } else {
                                _selectedModule.remove(value);
                              }
                            });
                          },
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.onPrimaryContainer,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // ── Notizen ──
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
