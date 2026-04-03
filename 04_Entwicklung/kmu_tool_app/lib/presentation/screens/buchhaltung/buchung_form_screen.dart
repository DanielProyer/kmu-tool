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
import 'package:kmu_tool_app/data/models/mwst_code.dart';
import 'package:kmu_tool_app/data/repositories/buchung_repository.dart';
import 'package:kmu_tool_app/data/repositories/buchungs_vorlage_repository.dart';
import 'package:kmu_tool_app/data/repositories/konto_repository.dart';
import 'package:kmu_tool_app/data/repositories/mwst_repository.dart';
import 'package:kmu_tool_app/services/mwst/mwst_service.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

// ─── Providers ───

final _kontenProvider = FutureProvider<List<Konto>>((ref) async {
  return KontoRepository().getAll();
});

final _vorlagenProvider = FutureProvider<List<BuchungsVorlage>>((ref) async {
  final vorlagen = await BuchungsVorlageRepository().getAll();
  // Sort by usage frequency: count how often each soll/haben combo appears
  final buchungen = await BuchungRepository().getAll();
  final usage = <String, int>{};
  for (final b in buchungen) {
    final key = '${b.sollKonto}_${b.habenKonto}';
    usage[key] = (usage[key] ?? 0) + 1;
  }
  vorlagen.sort((a, b) {
    final aCount = usage['${a.sollKonto}_${a.habenKonto}'] ?? 0;
    final bCount = usage['${b.sollKonto}_${b.habenKonto}'] ?? 0;
    return bCount.compareTo(aCount); // Most used first
  });
  return vorlagen;
});

final _mwstCodesProvider = FutureProvider<List<MwstCode>>((ref) async {
  return MwstRepository().getCodes();
});

final _mwstEinstellungProvider = FutureProvider<bool>((ref) async {
  final einstellung = await MwstRepository().getEinstellung();
  return einstellung?.isEffektiv ?? true;
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
  String? _mwstCode;
  double? _mwstSatz;

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _datum,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099, 12, 31),
      locale: const Locale('de', 'CH'),
      useRootNavigator: false,
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
          backgroundColor: AppStatusColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_sollKonto == _habenKonto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Soll- und Haben-Konto dürfen nicht identisch sein'),
          backgroundColor: AppStatusColors.error,
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
          backgroundColor: AppStatusColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // MWST-Betrag berechnen
      double? mwstBetrag;
      if (_mwstCode != null && _mwstCode != 'OHNE' && _mwstSatz != null && _mwstSatz! > 0) {
        mwstBetrag = double.parse((betrag * _mwstSatz! / 100).toStringAsFixed(2));
      }

      final userId = await BetriebService.getDataOwnerId();
      final buchung = Buchung(
        id: const Uuid().v4(),
        userId: userId,
        datum: _datum,
        sollKonto: _sollKonto!,
        habenKonto: _habenKonto!,
        betrag: betrag,
        beschreibung: _beschreibungController.text.trim(),
        belegNr: _belegNrController.text.trim().isNotEmpty
            ? _belegNrController.text.trim()
            : null,
        mwstCode: _mwstCode,
        mwstSatz: _mwstSatz,
        mwstBetrag: mwstBetrag,
      );

      await BuchungRepository().save(buchung);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Buchung gespeichert'),
            backgroundColor: AppStatusColors.success,
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
            backgroundColor: AppStatusColors.error,
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

  void _autoSuggestMwstCode(int kontonummer) {
    final mwstCodes = ref.read(_mwstCodesProvider).valueOrNull;
    if (mwstCodes == null) return;

    final isEffektiv = ref.read(_mwstEinstellungProvider).valueOrNull ?? true;
    final suggestedCode = MwstService.defaultMwstCodeForKonto(
        kontonummer, isEffektiv: isEffektiv);
    final code = mwstCodes.where((c) => c.code == suggestedCode).firstOrNull;
    if (code != null) {
      setState(() {
        _mwstCode = code.code;
        _mwstSatz = code.satz;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kontenAsync = ref.watch(_kontenProvider);
    final vorlagenAsync = ref.watch(_vorlagenProvider);
    ref.watch(_mwstCodesProvider); // Preload

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
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
                    size: 48, color: AppStatusColors.error),
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
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Buchungsvorlagen',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${vorlagen.length} Vorlagen',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        backgroundColor: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).dividerColor,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                _autoSuggestMwstCode(konto.kontonummer);
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                _autoSuggestMwstCode(konto.kontonummer);
              },
              hintText: 'Konto suchen...',
            ),
            const SizedBox(height: 20),

            // ── MWST-Code ──
            Text(
              'MWST-Code',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Builder(builder: (context) {
              final mwstCodesAsync = ref.watch(_mwstCodesProvider);
              return mwstCodesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('MWST-Codes nicht geladen'),
                data: (codes) {
                  return DropdownButtonFormField<String>(
                    value: _mwstCode,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.percent, size: 20),
                    ),
                    items: codes.map((c) {
                      return DropdownMenuItem(
                        value: c.code,
                        child: Text(
                          '${c.code} (${c.satz.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final code = codes.firstWhere((c) => c.code == value);
                        setState(() {
                          _mwstCode = code.code;
                          _mwstSatz = code.satz;
                        });
                      }
                    },
                  );
                },
              );
            }),
            if (_mwstCode != null && _mwstCode != 'OHNE')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'MWST ${_mwstSatz?.toStringAsFixed(1) ?? "-"}% wird automatisch berechnet',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
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
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
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
