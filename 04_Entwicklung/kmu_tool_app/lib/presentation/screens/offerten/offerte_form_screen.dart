import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/local/offert_position_local_export.dart';
import 'package:kmu_tool_app/data/local/artikel_local_export.dart';
import 'package:kmu_tool_app/data/repositories/offerte_repository.dart';
import 'package:kmu_tool_app/data/repositories/offert_position_repository.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/data/repositories/artikel_repository.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class OfferteFormScreen extends ConsumerStatefulWidget {
  final String? offerteId;
  final String? kundeId;

  const OfferteFormScreen({super.key, this.offerteId, this.kundeId});

  @override
  ConsumerState<OfferteFormScreen> createState() => _OfferteFormScreenState();
}

class _OfferteFormScreenState extends ConsumerState<OfferteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offertNrController = TextEditingController();
  final _mwstController = TextEditingController(text: '8.10');
  final _bemerkungController = TextEditingController();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  bool _isLoading = false;
  bool _isEdit = false;
  OfferteLocal? _existingOfferte;

  String? _selectedKundeId;
  DateTime _datum = DateTime.now();
  DateTime _gueltigBis = DateTime.now().add(const Duration(days: 30));

  final List<_PositionEntry> _positionen = [];

  @override
  void initState() {
    super.initState();
    _isEdit = widget.offerteId != null;
    if (_isEdit) {
      _loadOfferte();
    } else {
      _selectedKundeId = widget.kundeId;
      _generateOffertNr();
      // Start with one empty position
      _positionen.add(_PositionEntry());
    }
  }

  Future<void> _generateOffertNr() async {
    try {
      final year = DateTime.now().year;
      final prefix = 'OFF-$year-';
      final alleOfferten = await OfferteRepository.getAll();
      int maxNr = 0;
      for (final o in alleOfferten) {
        if (o.offertNr != null && o.offertNr!.startsWith(prefix)) {
          final nrStr = o.offertNr!.substring(prefix.length);
          final nr = int.tryParse(nrStr);
          if (nr != null && nr > maxNr) {
            maxNr = nr;
          }
        }
      }
      final nextNr = maxNr + 1;
      _offertNrController.text =
          '$prefix${nextNr.toString().padLeft(3, '0')}';
    } catch (_) {
      _offertNrController.text =
          'OFF-${DateTime.now().year}-001';
    }
  }

  Future<void> _loadOfferte() async {
    setState(() => _isLoading = true);
    try {
      final offerte = await OfferteRepository.getById(widget.offerteId!);
      if (offerte != null && mounted) {
        _existingOfferte = offerte;
        _offertNrController.text = offerte.offertNr ?? '';
        _selectedKundeId = offerte.kundeId;
        _datum = offerte.datum;
        _gueltigBis = offerte.gueltigBis ?? _gueltigBis;
        _mwstController.text = offerte.mwstSatz.toStringAsFixed(2);
        _bemerkungController.text = offerte.bemerkung ?? '';

        // Load positions
        final positionen =
            await OffertPositionRepository.getByOfferte(widget.offerteId!);
        _positionen.clear();
        for (final p in positionen) {
          _positionen.add(_PositionEntry(
            existingPosition: p,
            bezeichnungController:
                TextEditingController(text: p.bezeichnung),
            mengeController:
                TextEditingController(text: p.menge.toStringAsFixed(2)),
            einheitspreis:
                TextEditingController(text: p.einheitspreis.toStringAsFixed(2)),
            einheit: p.einheit ?? 'Stk',
            typ: p.typ,
            artikelId: p.artikelId,
          ));
        }
        if (_positionen.isEmpty) {
          _positionen.add(_PositionEntry());
        }
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

  double _calcPositionBetrag(_PositionEntry pos) {
    final menge = double.tryParse(pos.mengeController.text) ?? 0;
    final preis = double.tryParse(pos.einheitspreis.text) ?? 0;
    return menge * preis;
  }

  double get _totalNetto {
    double total = 0;
    for (final p in _positionen) {
      total += _calcPositionBetrag(p);
    }
    return total;
  }

  double get _mwstSatz => double.tryParse(_mwstController.text) ?? 8.1;

  double get _mwstBetrag => _totalNetto * _mwstSatz / 100;

  double get _totalBrutto => _totalNetto + _mwstBetrag;

  Future<void> _pickDate({required bool isGueltigBis}) async {
    final initial = isGueltigBis ? _gueltigBis : _datum;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2099),
      locale: const Locale('de', 'CH'),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isGueltigBis) {
          _gueltigBis = picked;
        } else {
          _datum = picked;
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

    // Validate that at least one position has a Bezeichnung
    final validPositionen = _positionen
        .where((p) => p.bezeichnungController.text.trim().isNotEmpty)
        .toList();
    if (validPositionen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte mindestens eine Position erfassen'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final offerte = _existingOfferte ?? OfferteLocal();

      if (!_isEdit) {
        offerte.serverId = const Uuid().v4();
      }

      offerte.kundeId = _selectedKundeId!;
      offerte.offertNr = _offertNrController.text.trim();
      offerte.datum = _datum;
      offerte.gueltigBis = _gueltigBis;
      offerte.mwstSatz = _mwstSatz;
      offerte.totalNetto =
          double.parse(_totalNetto.toStringAsFixed(2));
      offerte.mwstBetrag =
          double.parse(_mwstBetrag.toStringAsFixed(2));
      offerte.totalBrutto =
          double.parse(_totalBrutto.toStringAsFixed(2));
      offerte.bemerkung = _bemerkungController.text.trim().isEmpty
          ? null
          : _bemerkungController.text.trim();

      await OfferteRepository.save(offerte);

      // Determine the offerte ID for positions
      final offerteId = offerte.serverId ?? offerte.id.toString();

      // Save positions
      int posNr = 1;
      for (final pos in validPositionen) {
        final position =
            pos.existingPosition ?? OffertPositionLocal();

        if (pos.existingPosition == null) {
          position.serverId = const Uuid().v4();
        }

        position.offerteId = offerteId;
        position.positionNr = posNr++;
        position.bezeichnung = pos.bezeichnungController.text.trim();
        position.menge =
            double.tryParse(pos.mengeController.text) ?? 1.0;
        position.einheit = pos.einheit;
        position.einheitspreis =
            double.tryParse(pos.einheitspreis.text) ?? 0.0;
        position.betrag = double.parse(
            (position.menge * position.einheitspreis)
                .toStringAsFixed(2));
        position.typ = pos.typ;
        position.artikelId = pos.artikelId;

        await OffertPositionRepository.save(position);
      }

      // Delete removed positions (positions in edit mode that are no longer present)
      if (_isEdit) {
        final existingPositionen =
            await OffertPositionRepository.getByOfferte(widget.offerteId!);
        final keptIds = validPositionen
            .where((p) => p.existingPosition != null)
            .map((p) => p.existingPosition!.id)
            .toSet();
        for (final existing in existingPositionen) {
          if (!keptIds.contains(existing.id)) {
            await OffertPositionRepository.delete(
                existing.serverId ?? existing.id.toString());
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Offerte aktualisiert' : 'Offerte erstellt'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(offertenListProvider);
        if (_isEdit) {
          ref.invalidate(offerteProvider(widget.offerteId!));
          ref.invalidate(
              offertPositionenProvider(widget.offerteId!));
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
    _offertNrController.dispose();
    _mwstController.dispose();
    _bemerkungController.dispose();
    for (final p in _positionen) {
      p.dispose();
    }
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
              : context.go('/offerten'),
        ),
        title: Text(_isEdit ? 'Offerte bearbeiten' : 'Neue Offerte'),
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
      body: _isLoading && _isEdit && _existingOfferte == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                            setState(() => _selectedKundeId = value);
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

                    // ─── Offert-Nr ───
                    TextFormField(
                      controller: _offertNrController,
                      decoration: const InputDecoration(
                        labelText: 'Offert-Nr',
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

                    // ─── Datum / Gueltig bis ───
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _pickDate(isGueltigBis: false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Datum',
                                prefixIcon:
                                    Icon(Icons.calendar_today_outlined),
                              ),
                              child: Text(_dateFormat.format(_datum)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () =>
                                _pickDate(isGueltigBis: true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Gueltig bis',
                                prefixIcon:
                                    Icon(Icons.event_outlined),
                              ),
                              child: Text(
                                  _dateFormat.format(_gueltigBis)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ─── MWST-Satz ───
                    TextFormField(
                      controller: _mwstController,
                      decoration: const InputDecoration(
                        labelText: 'MWST-Satz (%)',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pflichtfeld';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Ungueltige Zahl';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Positionen ───
                    const Text(
                      'POSITIONEN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._positionen.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pos = entry.value;
                      return _PositionCard(
                        position: pos,
                        posNr: index + 1,
                        betrag: _calcPositionBetrag(pos),
                        onChanged: () => setState(() {}),
                        onTypChanged: (typ) {
                          setState(() => pos.typ = typ);
                        },
                        onArtikelSelected: (artikel) {
                          setState(() {
                            pos.artikelId = artikel.serverId;
                            pos.bezeichnungController.text = artikel.bezeichnung;
                            pos.einheitspreis.text =
                                artikel.verkaufspreis.toStringAsFixed(2);
                            pos.einheit = artikel.einheit ?? 'Stk';
                          });
                        },
                        onDelete: _positionen.length > 1
                            ? () {
                                setState(() {
                                  _positionen.removeAt(index);
                                });
                              }
                            : null,
                      );
                    }),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _positionen.add(_PositionEntry(
                                  typ: 'arbeit',
                                  einheit: 'Std',
                                ));
                              });
                            },
                            icon: const Icon(Icons.build_outlined, size: 18),
                            label: const Text('+ Arbeit'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _positionen.add(_PositionEntry(
                                  typ: 'material',
                                  einheit: 'Stk',
                                ));
                              });
                            },
                            icon: const Icon(Icons.inventory_2_outlined, size: 18),
                            label: const Text('+ Material'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Totals ───
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _TotalRow(
                              label: 'Netto',
                              value:
                                  'CHF ${_totalNetto.toStringAsFixed(2)}',
                            ),
                            _TotalRow(
                              label:
                                  'MWST (${_mwstSatz.toStringAsFixed(1)}%)',
                              value:
                                  'CHF ${_mwstBetrag.toStringAsFixed(2)}',
                            ),
                            const Divider(),
                            _TotalRow(
                              label: 'Brutto',
                              value:
                                  'CHF ${_totalBrutto.toStringAsFixed(2)}',
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Bemerkung ───
                    const Text(
                      'BEMERKUNG',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bemerkungController,
                      decoration: const InputDecoration(
                        labelText: 'Bemerkung',
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

// ─── Position Entry Model ───

class _PositionEntry {
  final OffertPositionLocal? existingPosition;
  final TextEditingController bezeichnungController;
  final TextEditingController mengeController;
  final TextEditingController einheitspreis;
  String einheit;
  String typ;
  String? artikelId;

  _PositionEntry({
    this.existingPosition,
    TextEditingController? bezeichnungController,
    TextEditingController? mengeController,
    TextEditingController? einheitspreis,
    this.einheit = 'Stk',
    this.typ = 'arbeit',
    this.artikelId,
  })  : bezeichnungController =
            bezeichnungController ?? TextEditingController(),
        mengeController =
            mengeController ?? TextEditingController(text: '1.00'),
        einheitspreis =
            einheitspreis ?? TextEditingController(text: '0.00');

  bool get isMaterial => typ == 'material';
  bool get isArbeit => typ == 'arbeit';

  void dispose() {
    bezeichnungController.dispose();
    mengeController.dispose();
    einheitspreis.dispose();
  }
}

// ─── Position Card Widget ───

class _PositionCard extends StatelessWidget {
  final _PositionEntry position;
  final int posNr;
  final double betrag;
  final VoidCallback onChanged;
  final ValueChanged<String> onTypChanged;
  final ValueChanged<ArtikelLocal> onArtikelSelected;
  final VoidCallback? onDelete;

  static const List<String> _einheiten = [
    'Stk',
    'Std',
    'm',
    'm\u00B2',
    'kg',
    'Pauschal',
  ];

  const _PositionCard({
    required this.position,
    required this.posNr,
    required this.betrag,
    required this.onChanged,
    required this.onTypChanged,
    required this.onArtikelSelected,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isArbeit = position.isArbeit;
    final typColor = isArbeit ? AppColors.info : AppColors.secondary;
    final typIcon = isArbeit ? Icons.build_outlined : Icons.inventory_2_outlined;
    final typLabel = isArbeit ? 'Arbeit' : 'Material';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: typColor.withValues(alpha: 0.1),
                  child: Icon(typIcon, size: 14, color: typColor),
                ),
                const SizedBox(width: 8),
                // Type badge
                GestureDetector(
                  onTap: () {
                    onTypChanged(isArbeit ? 'material' : 'arbeit');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          typLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: typColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.swap_horiz, size: 12, color: typColor),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Pos. $posNr',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.error),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Artikel search for material positions
            if (position.isMaterial) ...[
              _ArtikelSearchField(
                onSelected: onArtikelSelected,
                currentArtikelId: position.artikelId,
              ),
              const SizedBox(height: 8),
            ],

            TextFormField(
              controller: position.bezeichnungController,
              decoration: InputDecoration(
                labelText: 'Bezeichnung *',
                isDense: true,
                hintText: isArbeit
                    ? 'z.B. Sanitaerinstallation'
                    : 'z.B. Kupferrohr 22mm',
              ),
              onChanged: (_) => onChanged(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Pflichtfeld';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: position.mengeController,
                    decoration: const InputDecoration(
                      labelText: 'Menge',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: position.einheit,
                    decoration: const InputDecoration(
                      labelText: 'Einheit',
                      isDense: true,
                    ),
                    items: _einheiten.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        position.einheit = value;
                        onChanged();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: position.einheitspreis,
                    decoration: const InputDecoration(
                      labelText: 'Einheitspreis (CHF)',
                      isDense: true,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(
                            decimal: true),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Betrag: CHF ${betrag.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Artikel Search Widget ───

class _ArtikelSearchField extends StatefulWidget {
  final ValueChanged<ArtikelLocal> onSelected;
  final String? currentArtikelId;

  const _ArtikelSearchField({
    required this.onSelected,
    this.currentArtikelId,
  });

  @override
  State<_ArtikelSearchField> createState() => _ArtikelSearchFieldState();
}

class _ArtikelSearchFieldState extends State<_ArtikelSearchField> {
  List<ArtikelLocal> _results = [];
  bool _isSearching = false;
  final _searchController = TextEditingController();

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await ArtikelRepository.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _isSearching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Artikel suchen',
            isDense: true,
            prefixIcon: const Icon(Icons.search, size: 20),
            hintText: 'Name oder Artikelnummer...',
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
          ),
          onChanged: _search,
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            constraints: const BoxConstraints(maxHeight: 150),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              padding: EdgeInsets.zero,
              itemBuilder: (context, index) {
                final artikel = _results[index];
                final name = artikel.bezeichnung;
                final nr = artikel.artikelNr ?? '';
                final preis = artikel.verkaufspreis;
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    name,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '$nr · CHF ${preis.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    widget.onSelected(artikel);
                    _searchController.clear();
                    setState(() => _results = []);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─── Total Row Widget ───

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
