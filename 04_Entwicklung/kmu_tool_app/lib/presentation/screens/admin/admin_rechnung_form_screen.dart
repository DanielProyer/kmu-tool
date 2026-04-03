import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/admin/admin_rechnung.dart';
import 'package:kmu_tool_app/data/models/admin/admin_kundenprofil.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_rechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_kundenprofil_repository.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

// ─── Providers ───

final _kundenListProvider =
    FutureProvider<List<AdminKundenprofil>>((ref) async {
  return AdminKundenprofilRepository.getAll();
});

// ─── Screen ───

class AdminRechnungFormScreen extends ConsumerStatefulWidget {
  final String? rechnungId;
  final String? kundeProfilId;

  const AdminRechnungFormScreen({
    super.key,
    this.rechnungId,
    this.kundeProfilId,
  });

  @override
  ConsumerState<AdminRechnungFormScreen> createState() =>
      _AdminRechnungFormScreenState();
}

class _AdminRechnungFormScreenState
    extends ConsumerState<AdminRechnungFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');

  bool _isLoading = true;
  bool _isSaving = false;
  String? _existingId;

  // Form fields
  String? _selectedKundeId;
  final _rechnungsNrController = TextEditingController();
  DateTime? _periodeVon;
  DateTime? _periodeBis;
  final _planBezeichnungController = TextEditingController();
  final _betragController = TextEditingController();
  final _mwstSatzController = TextEditingController(text: '8.1');
  DateTime? _faelligAm;
  String _status = 'offen';
  final _notizenController = TextEditingController();

  // Auto-calculated
  double _mwstBetrag = 0;
  double _total = 0;

  static const _statusOptions = ['offen', 'bezahlt', 'storniert', 'gemahnt'];
  static const _statusLabels = {
    'offen': 'Offen',
    'bezahlt': 'Bezahlt',
    'storniert': 'Storniert',
    'gemahnt': 'Gemahnt',
  };

  @override
  void initState() {
    super.initState();
    _betragController.addListener(_recalculate);
    _mwstSatzController.addListener(_recalculate);
    _loadData();
  }

  @override
  void dispose() {
    _rechnungsNrController.dispose();
    _planBezeichnungController.dispose();
    _betragController.dispose();
    _mwstSatzController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final betrag = _parseBetrag(_betragController.text);
    final mwstSatz = double.tryParse(
            _mwstSatzController.text.replaceAll(',', '.')) ??
        0;
    setState(() {
      _mwstBetrag =
          double.parse((betrag * mwstSatz / 100).toStringAsFixed(2));
      _total = double.parse((betrag + _mwstBetrag).toStringAsFixed(2));
    });
  }

  double _parseBetrag(String text) {
    return double.tryParse(
            text.replaceAll("'", '').replaceAll(',', '.')) ??
        0;
  }

  Future<void> _loadData() async {
    try {
      if (widget.rechnungId != null) {
        // Edit mode: load existing
        final rechnung =
            await AdminRechnungRepository.getById(widget.rechnungId!);
        if (rechnung != null && mounted) {
          _existingId = rechnung.id;
          _selectedKundeId = rechnung.kundeProfilId;
          _rechnungsNrController.text = rechnung.rechnungsNr;
          _periodeVon = rechnung.periodeVon;
          _periodeBis = rechnung.periodeBis;
          _planBezeichnungController.text = rechnung.planBezeichnung ?? '';
          _betragController.text = rechnung.betrag.toStringAsFixed(2);
          _mwstSatzController.text = rechnung.mwstSatz.toStringAsFixed(1);
          _faelligAm = rechnung.faelligAm;
          _status = rechnung.status;
          _notizenController.text = rechnung.notizen ?? '';
          _recalculate();
        }
      } else {
        // New mode: generate next rechnungsNr
        final nextNr = await AdminRechnungRepository.nextRechnungsNr();
        if (mounted) {
          _rechnungsNrController.text = nextNr;
        }
        // Pre-select customer if passed
        if (widget.kundeProfilId != null) {
          _selectedKundeId = widget.kundeProfilId;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: AppStatusColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDate({
    required DateTime? currentValue,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentValue ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2099, 12, 31),
      locale: const Locale('de', 'CH'),
      useRootNavigator: false,
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  /// Formats a double as Swiss CHF with apostrophe thousands separator.
  static String _formatCHF(double amount) {
    if (amount == 0) return 'CHF 0.00';
    final isNegative = amount < 0;
    final abs = amount.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write("'");
      }
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}CHF $buffer.$decPart';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKundeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte einen Kunden auswaehlen'),
          backgroundColor: AppStatusColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final betrag = _parseBetrag(_betragController.text);
    if (betrag <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Betrag muss groesser als 0 sein'),
          backgroundColor: AppStatusColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final mwstSatz = double.tryParse(
              _mwstSatzController.text.replaceAll(',', '.')) ??
          8.1;
      final mwstBetrag =
          double.parse((betrag * mwstSatz / 100).toStringAsFixed(2));
      final total = double.parse((betrag + mwstBetrag).toStringAsFixed(2));

      final rechnung = AdminRechnung(
        id: _existingId ?? const Uuid().v4(),
        kundeProfilId: _selectedKundeId!,
        rechnungsNr: _rechnungsNrController.text.trim(),
        periodeVon: _periodeVon,
        periodeBis: _periodeBis,
        planBezeichnung: _planBezeichnungController.text.trim().isNotEmpty
            ? _planBezeichnungController.text.trim()
            : null,
        betrag: betrag,
        mwstSatz: mwstSatz,
        mwstBetrag: mwstBetrag,
        total: total,
        status: _status,
        bezahltAm: _status == 'bezahlt' ? DateTime.now() : null,
        faelligAm: _faelligAm,
        notizen: _notizenController.text.trim().isNotEmpty
            ? _notizenController.text.trim()
            : null,
      );

      await AdminRechnungRepository.save(rechnung);

      ref.invalidate(adminRechnungenListProvider);
      ref.invalidate(adminDashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_existingId != null
                ? 'Rechnung aktualisiert'
                : 'Rechnung erstellt'),
            backgroundColor: AppStatusColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kundenAsync = ref.watch(_kundenListProvider);
    final isEdit = widget.rechnungId != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/admin/rechnungen'),
        ),
        title: Text(isEdit ? 'Rechnung bearbeiten' : 'Neue Rechnung'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : kundenAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppStatusColors.error),
                      const SizedBox(height: 16),
                      Text('Fehler: $error'),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(_kundenListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (kunden) => _buildForm(context, kunden),
            ),
    );
  }

  Widget _buildForm(BuildContext context, List<AdminKundenprofil> kunden) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Kunde (Dropdown) ──
            Text(
              'Kunde *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedKundeId,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.business_outlined, size: 20),
                hintText: 'Kunde auswaehlen',
              ),
              isExpanded: true,
              items: kunden.map((k) {
                return DropdownMenuItem(
                  value: k.id,
                  child: Text(
                    k.firmaName,
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedKundeId = value);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Kunde ist erforderlich';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Rechnungs-Nr ──
            TextFormField(
              controller: _rechnungsNrController,
              decoration: const InputDecoration(
                labelText: 'Rechnungs-Nr.',
                prefixIcon: Icon(Icons.tag, size: 20),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Rechnungs-Nr. ist erforderlich';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Periode Von / Bis ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode von',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _pickDate(
                          currentValue: _periodeVon,
                          onPicked: (d) =>
                              setState(() => _periodeVon = d),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon:
                                Icon(Icons.calendar_today, size: 18),
                            isDense: true,
                          ),
                          child: Text(
                            _periodeVon != null
                                ? _dateFormat.format(_periodeVon!)
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: _periodeVon != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Periode bis',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _pickDate(
                          currentValue: _periodeBis,
                          onPicked: (d) =>
                              setState(() => _periodeBis = d),
                        ),
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            prefixIcon:
                                Icon(Icons.calendar_today, size: 18),
                            isDense: true,
                          ),
                          child: Text(
                            _periodeBis != null
                                ? _dateFormat.format(_periodeBis!)
                                : '-',
                            style: TextStyle(
                              fontSize: 14,
                              color: _periodeBis != null
                                  ? colorScheme.onSurface
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Plan-Bezeichnung ──
            TextFormField(
              controller: _planBezeichnungController,
              decoration: const InputDecoration(
                labelText: 'Plan-Bezeichnung',
                prefixIcon: Icon(Icons.label_outline, size: 20),
                hintText: 'z.B. Standard April 2026',
              ),
            ),
            const SizedBox(height: 20),

            // ── Betrag ──
            TextFormField(
              controller: _betragController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\d.,\x27]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Betrag CHF *',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Betrag ist erforderlich';
                }
                final parsed = _parseBetrag(value);
                if (parsed <= 0) {
                  return 'Gueltigen Betrag eingeben (> 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── MWST-Satz ──
            TextFormField(
              controller: _mwstSatzController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\d.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'MWST-Satz %',
                prefixIcon: Icon(Icons.percent, size: 20),
                hintText: '8.1',
              ),
            ),
            const SizedBox(height: 12),

            // ── Auto-calculated summary ──
            Card(
              color: colorScheme.surfaceContainerHighest,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _CalcRow(
                      label: 'Netto',
                      value: _formatCHF(
                          _parseBetrag(_betragController.text)),
                    ),
                    const SizedBox(height: 6),
                    _CalcRow(
                      label: 'MWST',
                      value: _formatCHF(_mwstBetrag),
                    ),
                    const Divider(height: 16),
                    _CalcRow(
                      label: 'Total',
                      value: _formatCHF(_total),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Faellig am ──
            Text(
              'Faellig am',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => _pickDate(
                currentValue: _faelligAm,
                onPicked: (d) => setState(() => _faelligAm = d),
              ),
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.event_outlined, size: 20),
                ),
                child: Text(
                  _faelligAm != null
                      ? _dateFormat.format(_faelligAm!)
                      : 'Datum auswaehlen',
                  style: TextStyle(
                    fontSize: 15,
                    color: _faelligAm != null
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Status ──
            Text(
              'Status',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.flag_outlined, size: 20),
              ),
              items: _statusOptions.map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(
                    _statusLabels[s] ?? s,
                    style: const TextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _status = value);
                }
              },
            ),
            const SizedBox(height: 20),

            // ── Notizen ──
            TextFormField(
              controller: _notizenController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notizen',
                prefixIcon: Icon(Icons.notes_outlined, size: 20),
                alignLabelWithHint: true,
                hintText: 'Optionale Bemerkungen...',
              ),
            ),
            const SizedBox(height: 32),

            // ── Save Button ──
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.rechnungId != null
                      ? 'Rechnung aktualisieren'
                      : 'Rechnung erstellen'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Calculation Row ───

class _CalcRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _CalcRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isBold
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
