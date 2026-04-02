import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/buchung.dart';
import 'package:kmu_tool_app/data/models/buchungs_vorlage.dart';
import 'package:kmu_tool_app/data/models/konto.dart';
import 'package:kmu_tool_app/data/repositories/buchung_repository.dart';
import 'package:kmu_tool_app/data/repositories/buchungs_vorlage_repository.dart';
import 'package:kmu_tool_app/data/repositories/konto_repository.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

// ─── Providers ───

final _kontenProvider = FutureProvider<List<Konto>>((ref) async {
  return KontoRepository().getAll();
});

final _vorlagenProvider = FutureProvider<List<BuchungsVorlage>>((ref) async {
  return BuchungsVorlageRepository().getAll();
});

// ─── Screen ───

class BuchungFormScreen extends ConsumerStatefulWidget {
  const BuchungFormScreen({super.key});

  @override
  ConsumerState<BuchungFormScreen> createState() => _BuchungFormScreenState();
}

class _BuchungFormScreenState extends ConsumerState<BuchungFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateFmt = DateFormat('dd.MM.yyyy', 'de_CH');

  DateTime _datum = DateTime.now();
  int? _sollKonto;
  int? _habenKonto;
  final _betragController = TextEditingController();
  final _beschreibungController = TextEditingController();
  final _belegNrController = TextEditingController();

  bool _isSaving = false;
  bool _showVorlagen = false;

  // Search state for account dropdowns
  String _sollSearchQuery = '';
  String _habenSearchQuery = '';

  @override
  void dispose() {
    _betragController.dispose();
    _beschreibungController.dispose();
    _belegNrController.dispose();
    super.dispose();
  }

  List<Konto> _filterKonten(List<Konto> konten, String query) {
    if (query.isEmpty) return konten;
    final q = query.toLowerCase();
    return konten.where((k) {
      return k.kontonummer.toString().contains(q) ||
          k.bezeichnung.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099, 12, 31),
      locale: const Locale('de', 'CH'),
    );
    if (picked != null) {
      setState(() => _datum = picked);
    }
  }

  void _applyVorlage(BuchungsVorlage vorlage) {
    setState(() {
      _sollKonto = vorlage.sollKonto;
      _habenKonto = vorlage.habenKonto;
      if (_beschreibungController.text.isEmpty) {
        _beschreibungController.text = vorlage.bezeichnung;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vorlage "${vorlage.bezeichnung}" angewendet'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_sollKonto == null || _habenKonto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte Soll- und Haben-Konto auswählen'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_sollKonto == _habenKonto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Soll- und Haben-Konto dürfen nicht identisch sein'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final betrag = double.tryParse(
        _betragController.text.replaceAll("'", '').replaceAll(',', '.'));
    if (betrag == null || betrag <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Betrag muss grösser als 0 sein'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final buchung = Buchung(
        id: const Uuid().v4(),
        userId: SupabaseService.currentUser!.id,
        datum: _datum,
        sollKonto: _sollKonto!,
        habenKonto: _habenKonto!,
        betrag: betrag,
        beschreibung: _beschreibungController.text.trim(),
        belegNr: _belegNrController.text.trim().isNotEmpty
            ? _belegNrController.text.trim()
            : null,
      );

      await BuchungRepository().save(buchung);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buchung gespeichert'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
    final kontenAsync = ref.watch(_kontenProvider);
    final vorlagenAsync = ref.watch(_vorlagenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neue Buchung'),
      ),
      body: kontenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Fehler: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(_kontenProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (konten) {
          final vorlagen = vorlagenAsync.valueOrNull ?? [];
          return _buildForm(context, konten, vorlagen);
        },
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    List<Konto> konten,
    List<BuchungsVorlage> vorlagen,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Quick-Buchung Vorlagen ──
            if (vorlagen.isNotEmpty) ...[
              InkWell(
                onTap: () => setState(() => _showVorlagen = !_showVorlagen),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        _showVorlagen
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Buchungsvorlagen',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${vorlagen.length} Vorlagen',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_showVorlagen)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: vorlagen.map((v) {
                      final isSelected = _sollKonto == v.sollKonto &&
                          _habenKonto == v.habenKonto;
                      return ActionChip(
                        label: Text(
                          v.bezeichnung,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceCard,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                        onPressed: () => _applyVorlage(v),
                      );
                    }).toList(),
                  ),
                ),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // ── Datum ──
            Text(
              'Datum',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(10),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(
                  _dateFmt.format(_datum),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Soll-Konto ──
            Text(
              'Soll-Konto (Belastung)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            _KontoSearchDropdown(
              konten: konten,
              selectedKontonummer: _sollKonto,
              searchQuery: _sollSearchQuery,
              onSearchChanged: (q) =>
                  setState(() => _sollSearchQuery = q),
              onSelected: (konto) {
                setState(() {
                  _sollKonto = konto.kontonummer;
                  _sollSearchQuery = '';
                });
              },
              hintText: 'Konto suchen...',
            ),
            const SizedBox(height: 20),

            // ── Haben-Konto ──
            Text(
              'Haben-Konto (Gutschrift)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            _KontoSearchDropdown(
              konten: konten,
              selectedKontonummer: _habenKonto,
              searchQuery: _habenSearchQuery,
              onSearchChanged: (q) =>
                  setState(() => _habenSearchQuery = q),
              onSelected: (konto) {
                setState(() {
                  _habenKonto = konto.kontonummer;
                  _habenSearchQuery = '';
                });
              },
              hintText: 'Konto suchen...',
            ),
            const SizedBox(height: 20),

            // ── Betrag CHF ──
            TextFormField(
              controller: _betragController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'[\d.,\x27]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Betrag CHF',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
                hintText: '0.00',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Betrag ist erforderlich';
                }
                final parsed = double.tryParse(
                    value.replaceAll("'", '').replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Gültigen Betrag eingeben (> 0)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Beschreibung ──
            TextFormField(
              controller: _beschreibungController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                prefixIcon: Icon(Icons.description_outlined, size: 20),
                hintText: 'z.B. Materialrechnung Lieferant XY',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Beschreibung ist erforderlich';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Beleg-Nr ──
            TextFormField(
              controller: _belegNrController,
              decoration: const InputDecoration(
                labelText: 'Beleg-Nr. (optional)',
                prefixIcon: Icon(Icons.tag, size: 20),
                hintText: 'z.B. RE-2026-001',
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
                  : const Text('Buchung speichern'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Searchable Konto Dropdown ───

class _KontoSearchDropdown extends StatefulWidget {
  final List<Konto> konten;
  final int? selectedKontonummer;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<Konto> onSelected;
  final String hintText;

  const _KontoSearchDropdown({
    required this.konten,
    required this.selectedKontonummer,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onSelected,
    required this.hintText,
  });

  @override
  State<_KontoSearchDropdown> createState() => _KontoSearchDropdownState();
}

class _KontoSearchDropdownState extends State<_KontoSearchDropdown> {
  bool _isExpanded = false;
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<Konto> get _filtered {
    final q = _searchController.text.toLowerCase();
    if (q.isEmpty) return widget.konten;
    return widget.konten.where((k) {
      return k.kontonummer.toString().contains(q) ||
          k.bezeichnung.toLowerCase().contains(q);
    }).toList();
  }

  Konto? get _selectedKonto {
    if (widget.selectedKontonummer == null) return null;
    try {
      return widget.konten
          .firstWhere((k) => k.kontonummer == widget.selectedKontonummer);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedKonto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected value or tap to open
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _searchController.clear();
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _focusNode.requestFocus(),
                );
              }
            });
          },
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.account_balance_outlined, size: 20),
              suffixIcon: Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textSecondary,
              ),
            ),
            child: selected != null
                ? Text(
                    '${selected.kontonummer}  ${selected.bezeichnung}',
                    style: const TextStyle(fontSize: 15),
                  )
                : Text(
                    'Konto auswählen',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),

        // Expanded search + list
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: widget.hintText,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.divider),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.surfaceCard,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _filtered.length,
              itemBuilder: (context, index) {
                final konto = _filtered[index];
                final isActive =
                    konto.kontonummer == widget.selectedKontonummer;

                return InkWell(
                  onTap: () {
                    widget.onSelected(konto);
                    setState(() => _isExpanded = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${konto.kontonummer}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: isActive
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            konto.bezeichnung,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
