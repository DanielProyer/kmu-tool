import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/lager/lager_service.dart';
import 'package:kmu_tool_app/data/models/lagerort.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class LagerbewegungFormScreen extends ConsumerStatefulWidget {
  final String artikelId;

  const LagerbewegungFormScreen({super.key, required this.artikelId});

  @override
  ConsumerState<LagerbewegungFormScreen> createState() =>
      _LagerbewegungFormScreenState();
}

class _LagerbewegungFormScreenState
    extends ConsumerState<LagerbewegungFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mengeController = TextEditingController();
  final _bemerkungController = TextEditingController();

  String _bewegungstyp = 'eingang';
  String? _lagerortId;
  String? _zielLagerortId;
  bool _isSaving = false;

  static const _typen = [
    ('eingang', 'Wareneingang', Icons.arrow_downward),
    ('ausgang', 'Warenausgang', Icons.arrow_upward),
    ('umlagerung', 'Umlagerung', Icons.swap_horiz),
    ('korrektur', 'Korrektur', Icons.build),
  ];

  Color _typColor(String typ) {
    switch (typ) {
      case 'eingang':
        return AppStatusColors.success;
      case 'ausgang':
        return AppStatusColors.error;
      case 'umlagerung':
        return AppStatusColors.info;
      case 'korrektur':
        return AppStatusColors.warning;
      default:
        return AppStatusColors.storniert;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final menge = double.parse(_mengeController.text.trim());
      final bemerkung = _bemerkungController.text.trim().isEmpty
          ? null
          : _bemerkungController.text.trim();

      switch (_bewegungstyp) {
        case 'eingang':
          await LagerService.wareneingang(
            artikelId: widget.artikelId,
            lagerortId: _lagerortId!,
            menge: menge,
            bemerkung: bemerkung,
          );
          break;
        case 'ausgang':
          await LagerService.warenausgang(
            artikelId: widget.artikelId,
            lagerortId: _lagerortId!,
            menge: menge,
            bemerkung: bemerkung,
          );
          break;
        case 'umlagerung':
          await LagerService.umlagerung(
            artikelId: widget.artikelId,
            vonLagerortId: _lagerortId!,
            nachLagerortId: _zielLagerortId!,
            menge: menge,
            bemerkung: bemerkung,
          );
          break;
        case 'korrektur':
          await LagerService.korrektur(
            artikelId: widget.artikelId,
            lagerortId: _lagerortId!,
            menge: menge,
            bemerkung: bemerkung,
          );
          break;
      }

      if (mounted) {
        ref.invalidate(lagerbestandByArtikelProvider(widget.artikelId));
        ref.invalidate(lagerbewegungByArtikelProvider(widget.artikelId));
        ref.invalidate(artikelProvider(widget.artikelId));
        ref.invalidate(artikelListProvider);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lagerbewegung erfasst'),
            backgroundColor: AppStatusColors.success,
          ),
        );
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _mengeController.dispose();
    _bemerkungController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lagerorteAsync = ref.watch(lagerortListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/artikel/${widget.artikelId}'),
        ),
        title: const Text('Lagerbewegung erfassen'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
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
      body: lagerorteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text('Fehler beim Laden der Lagerorte: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(lagerortListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (lagerorte) {
          if (lagerorte.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      size: 72,
                      color: colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Lagerorte vorhanden',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle zuerst einen Lagerort unter Einstellungen.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Bewegungstyp ───
                  Text(
                    'Bewegungstyp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _typen.map((t) {
                      final isSelected = _bewegungstyp == t.$1;
                      final color = _typColor(t.$1);
                      return ChoiceChip(
                        avatar: Icon(
                          t.$3,
                          size: 18,
                          color: isSelected ? Colors.white : color,
                        ),
                        label: Text(t.$2),
                        selected: isSelected,
                        selectedColor: color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _bewegungstyp = t.$1;
                              // Reset zielLagerortId when switching away from umlagerung
                              if (t.$1 != 'umlagerung') {
                                _zielLagerortId = null;
                              }
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // ─── Von Lagerort ───
                  _LagerortDropdown(
                    label: _bewegungstyp == 'umlagerung'
                        ? 'Von Lagerort *'
                        : 'Lagerort *',
                    value: _lagerortId,
                    lagerorte: lagerorte,
                    excludeId: _zielLagerortId,
                    onChanged: (value) =>
                        setState(() => _lagerortId = value),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pflichtfeld';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ─── Nach Lagerort (nur bei Umlagerung) ───
                  if (_bewegungstyp == 'umlagerung') ...[
                    _LagerortDropdown(
                      label: 'Nach Lagerort *',
                      value: _zielLagerortId,
                      lagerorte: lagerorte,
                      excludeId: _lagerortId,
                      onChanged: (value) =>
                          setState(() => _zielLagerortId = value),
                      validator: (value) {
                        if (_bewegungstyp == 'umlagerung' &&
                            (value == null || value.isEmpty)) {
                          return 'Pflichtfeld';
                        }
                        if (value == _lagerortId) {
                          return 'Muss sich vom Quell-Lagerort unterscheiden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── Menge ───
                  TextFormField(
                    controller: _mengeController,
                    decoration: InputDecoration(
                      labelText: 'Menge *',
                      prefixIcon: const Icon(Icons.numbers_outlined),
                      hintText: _bewegungstyp == 'korrektur'
                          ? 'Positiv = Zugang, Negativ = Abgang'
                          : 'Anzahl eingeben',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Pflichtfeld';
                      }
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null) {
                        return 'Ungueltige Zahl';
                      }
                      if (_bewegungstyp != 'korrektur' && parsed <= 0) {
                        return 'Menge muss groesser als 0 sein';
                      }
                      if (_bewegungstyp == 'korrektur' && parsed == 0) {
                        return 'Menge darf nicht 0 sein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ─── Bemerkung ───
                  TextFormField(
                    controller: _bemerkungController,
                    decoration: const InputDecoration(
                      labelText: 'Bemerkung',
                      prefixIcon: Icon(Icons.notes_outlined),
                      hintText: 'Optionale Bemerkung zur Bewegung',
                    ),
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Lagerort Dropdown ───

class _LagerortDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<Lagerort> lagerorte;
  final String? excludeId;
  final ValueChanged<String?> onChanged;
  final FormFieldValidator<String>? validator;

  const _LagerortDropdown({
    required this.label,
    required this.value,
    required this.lagerorte,
    this.excludeId,
    required this.onChanged,
    this.validator,
  });

  IconData _typIcon(String typ) {
    switch (typ) {
      case 'lager':
        return Icons.warehouse_outlined;
      case 'fahrzeug':
        return Icons.local_shipping_outlined;
      case 'baustelle':
        return Icons.construction_outlined;
      default:
        return Icons.place_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        lagerorte.where((l) => l.id != excludeId).toList();

    return DropdownButtonFormField<String>(
      value: filtered.any((l) => l.id == value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.warehouse_outlined),
      ),
      items: filtered.map((lagerort) {
        return DropdownMenuItem<String>(
          value: lagerort.id,
          child: Row(
            children: [
              Icon(_typIcon(lagerort.typ), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lagerort.bezeichnung,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
