import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_repository.dart';
import 'package:kmu_tool_app/data/repositories/offerte_repository.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class AuftragFormScreen extends ConsumerStatefulWidget {
  final String? auftragId;
  final String? offerteId;

  const AuftragFormScreen({super.key, this.auftragId, this.offerteId});

  @override
  ConsumerState<AuftragFormScreen> createState() =>
      _AuftragFormScreenState();
}

class _AuftragFormScreenState extends ConsumerState<AuftragFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auftragsNrController = TextEditingController();
  final _beschreibungController = TextEditingController();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  bool _isLoading = false;
  bool _isEdit = false;
  AuftragLocal? _existingAuftrag;

  String? _selectedKundeId;
  String? _selectedStatus;
  DateTime? _geplantVon;
  DateTime? _geplantBis;

  // Linked offerte info (if created from an Offerte)
  String? _linkedOfferteNr;
  String? _linkedOfferteId;

  final Map<String, String> _statusLabels = const {
    'offen': 'Offen',
    'in_arbeit': 'In Arbeit',
    'abgeschlossen': 'Abgeschlossen',
    'storniert': 'Storniert',
  };

  @override
  void initState() {
    super.initState();
    _isEdit = widget.auftragId != null;
    _selectedStatus = 'offen';

    if (_isEdit) {
      _loadAuftrag();
    } else {
      _generateAuftragsNr();
      if (widget.offerteId != null) {
        _loadOfferte();
      }
    }
  }

  Future<void> _generateAuftragsNr() async {
    try {
      final year = DateTime.now().year;
      final prefix = 'AUF-$year-';
      final alleAuftraege = await AuftragRepository.getAll();
      int maxNr = 0;
      for (final a in alleAuftraege) {
        if (a.auftragsNr != null && a.auftragsNr!.startsWith(prefix)) {
          final nrStr = a.auftragsNr!.substring(prefix.length);
          final nr = int.tryParse(nrStr);
          if (nr != null && nr > maxNr) {
            maxNr = nr;
          }
        }
      }
      final nextNr = maxNr + 1;
      _auftragsNrController.text =
          '$prefix${nextNr.toString().padLeft(3, '0')}';
    } catch (_) {
      _auftragsNrController.text =
          'AUF-${DateTime.now().year}-001';
    }
  }

  Future<void> _loadOfferte() async {
    try {
      final offerte =
          await OfferteRepository.getById(widget.offerteId!);
      if (offerte != null && mounted) {
        setState(() {
          _selectedKundeId = offerte.kundeId;
          _linkedOfferteId = widget.offerteId;
          _linkedOfferteNr = offerte.offertNr ?? widget.offerteId;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadAuftrag() async {
    setState(() => _isLoading = true);
    try {
      final auftrag =
          await AuftragRepository.getById(widget.auftragId!);
      if (auftrag != null && mounted) {
        _existingAuftrag = auftrag;
        _auftragsNrController.text = auftrag.auftragsNr ?? '';
        _selectedKundeId = auftrag.kundeId;
        _selectedStatus = auftrag.status;
        _beschreibungController.text = auftrag.beschreibung ?? '';
        _geplantVon = auftrag.geplantVon;
        _geplantBis = auftrag.geplantBis;
        _linkedOfferteId = auftrag.offerteId;
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

  Future<void> _pickDate({required bool isBis}) async {
    final initial = isBis
        ? (_geplantBis ?? DateTime.now())
        : (_geplantVon ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      locale: const Locale('de', 'CH'),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isBis) {
          _geplantBis = picked;
        } else {
          _geplantVon = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKundeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte einen Kunden auswaehlen'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auftrag = _existingAuftrag ?? AuftragLocal();

      if (!_isEdit) {
        auftrag.serverId = const Uuid().v4();
      }

      auftrag.kundeId = _selectedKundeId!;
      auftrag.auftragsNr = _auftragsNrController.text.trim();
      auftrag.status = _selectedStatus ?? 'offen';
      auftrag.beschreibung =
          _beschreibungController.text.trim().isEmpty
              ? null
              : _beschreibungController.text.trim();
      auftrag.geplantVon = _geplantVon;
      auftrag.geplantBis = _geplantBis;
      auftrag.offerteId = _linkedOfferteId;

      await AuftragRepository.save(auftrag);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Auftrag aktualisiert' : 'Auftrag erstellt'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(auftraegeListProvider);
        if (_isEdit) {
          ref.invalidate(auftragProvider(widget.auftragId!));
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
    _auftragsNrController.dispose();
    _beschreibungController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kundenAsync = ref.watch(kundenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/auftraege'),
        ),
        title: Text(_isEdit ? 'Auftrag bearbeiten' : 'Neuer Auftrag'),
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
      body: _isLoading && _isEdit && _existingAuftrag == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Verknuepfte Offerte (info only) ───
                    if (_linkedOfferteNr != null) ...[
                      Card(
                        color: AppColors.primary
                            .withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.link,
                                  size: 20,
                                  color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Verknuepft mit Offerte: $_linkedOfferteNr',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── Kunde ───
                    kundenAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('Fehler: $e'),
                      data: (kunden) {
                        return DropdownButtonFormField<String>(
                          value: _selectedKundeId,
                          decoration: const InputDecoration(
                            labelText: 'Kunde auswaehlen *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: kunden.map((k) {
                            final name = k.firma ??
                                '${k.vorname ?? ''} ${k.nachname}'
                                    .trim();
                            return DropdownMenuItem(
                              value: k.serverId ?? k.id.toString(),
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(
                                () => _selectedKundeId = value);
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Pflichtfeld';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Auftrags-Nr ───
                    TextFormField(
                      controller: _auftragsNrController,
                      decoration: const InputDecoration(
                        labelText: 'Auftrags-Nr',
                        prefixIcon: Icon(Icons.tag),
                      ),
                      readOnly: !_isEdit,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pflichtfeld';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Beschreibung ───
                    const Text(
                      'BESCHREIBUNG',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _beschreibungController,
                      decoration: const InputDecoration(
                        labelText: 'Beschreibung',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 24),

                    // ─── Zeitraum ───
                    const Text(
                      'ZEITRAUM',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isBis: false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Geplant von',
                                prefixIcon: Icon(
                                    Icons.calendar_today_outlined),
                              ),
                              child: Text(
                                _geplantVon != null
                                    ? _dateFormat
                                        .format(_geplantVon!)
                                    : '–',
                                style: TextStyle(
                                  color: _geplantVon != null
                                      ? null
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(isBis: true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Geplant bis',
                                prefixIcon:
                                    Icon(Icons.event_outlined),
                              ),
                              child: Text(
                                _geplantBis != null
                                    ? _dateFormat
                                        .format(_geplantBis!)
                                    : '–',
                                style: TextStyle(
                                  color: _geplantBis != null
                                      ? null
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Status (nur bei Bearbeitung) ───
                    if (_isEdit) ...[
                      const Text(
                        'STATUS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: _statusLabels.entries.map((entry) {
                          return DropdownMenuItem(
                            value: entry.key,
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: _statusColor(entry.key),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(entry.value),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(
                              () => _selectedStatus = value);
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'offen':
        return AppColors.offen;
      case 'in_arbeit':
        return AppColors.inBearbeitung;
      case 'abgeschlossen':
        return AppColors.abgeschlossen;
      case 'storniert':
        return AppColors.storniert;
      default:
        return AppColors.storniert;
    }
  }
}
