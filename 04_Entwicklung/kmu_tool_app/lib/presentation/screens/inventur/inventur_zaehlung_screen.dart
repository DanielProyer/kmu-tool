import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/inventur_position.dart';
import 'package:kmu_tool_app/data/repositories/inventur_position_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class InventurZaehlungScreen extends ConsumerStatefulWidget {
  final String inventurId;

  const InventurZaehlungScreen({super.key, required this.inventurId});

  @override
  ConsumerState<InventurZaehlungScreen> createState() =>
      _InventurZaehlungScreenState();
}

class _InventurZaehlungScreenState
    extends ConsumerState<InventurZaehlungScreen> {
  int _currentIndex = 0;
  bool _skipGezaehlte = false;
  bool _isSaving = false;

  final _istBestandController = TextEditingController();
  final _bemerkungController = TextEditingController();
  final _istBestandFocus = FocusNode();

  @override
  void dispose() {
    _istBestandController.dispose();
    _bemerkungController.dispose();
    _istBestandFocus.dispose();
    super.dispose();
  }

  List<InventurPosition> _getPositionen(List<InventurPosition> all) {
    if (_skipGezaehlte) {
      return all.where((p) => !p.gezaehlt).toList();
    }
    return all;
  }

  void _loadPositionValues(InventurPosition position) {
    if (position.gezaehlt && position.istBestand != null) {
      _istBestandController.text = position.istBestand!.toStringAsFixed(
        position.istBestand! == position.istBestand!.roundToDouble() ? 0 : 2,
      );
    } else {
      _istBestandController.clear();
    }
    _bemerkungController.text = position.bemerkung ?? '';

    // Auto-focus the input field after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _istBestandFocus.requestFocus();
    });
  }

  Future<bool> _saveCurrentCount(InventurPosition position) async {
    final text = _istBestandController.text.trim();
    if (text.isEmpty) return true; // skip if empty

    final istBestand = double.tryParse(text.replaceAll(',', '.'));
    if (istBestand == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bitte eine gueltige Zahl eingeben'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
      return false;
    }

    setState(() => _isSaving = true);
    try {
      final bemerkung = _bemerkungController.text.trim();
      await InventurPositionRepository.erfasseZaehlung(
        position.id,
        istBestand,
        bemerkung: bemerkung.isNotEmpty ? bemerkung : null,
      );
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _goNext(List<InventurPosition> positionen) async {
    if (_currentIndex >= positionen.length) return;

    final saved = await _saveCurrentCount(positionen[_currentIndex]);
    if (!saved) return;

    ref.invalidate(inventurPositionenProvider(widget.inventurId));

    if (_currentIndex < positionen.length - 1) {
      setState(() {
        _currentIndex++;
        _istBestandController.clear();
        _bemerkungController.clear();
      });
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) _istBestandFocus.requestFocus();
      });
    }
  }

  Future<void> _goBack(List<InventurPosition> positionen) async {
    if (_currentIndex <= 0) return;
    setState(() => _currentIndex--);
    _loadPositionValues(positionen[_currentIndex]);
  }

  Future<void> _finish(List<InventurPosition> positionen) async {
    if (_currentIndex < positionen.length) {
      final saved = await _saveCurrentCount(positionen[_currentIndex]);
      if (!saved) return;
    }

    // Refresh providers before navigating back
    ref.invalidate(inventurPositionenProvider(widget.inventurId));
    ref.invalidate(inventurProvider(widget.inventurId));

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final positionenAsync =
        ref.watch(inventurPositionenProvider(widget.inventurId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.invalidate(inventurPositionenProvider(widget.inventurId));
            ref.invalidate(inventurProvider(widget.inventurId));
            context.pop();
          },
        ),
        title: const Text('Zaehlung'),
        actions: [
          // Skip toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Gezaehlte\nueberspringen',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.right,
              ),
              Switch(
                value: _skipGezaehlte,
                onChanged: (value) {
                  setState(() {
                    _skipGezaehlte = value;
                    _currentIndex = 0;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: positionenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text('Fehler: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(
                      inventurPositionenProvider(widget.inventurId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (allPositionen) {
          final positionen = _getPositionen(allPositionen);

          if (positionen.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 72,
                      color: AppStatusColors.success,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _skipGezaehlte
                          ? 'Alle Positionen sind gezaehlt'
                          : 'Keine Positionen vorhanden',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        ref.invalidate(
                            inventurPositionenProvider(widget.inventurId));
                        ref.invalidate(inventurProvider(widget.inventurId));
                        context.pop();
                      },
                      child: const Text('Zurueck zur Uebersicht'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Clamp index
          if (_currentIndex >= positionen.length) {
            _currentIndex = positionen.length - 1;
          }

          final position = positionen[_currentIndex];
          final isLast = _currentIndex == positionen.length - 1;
          final isFirst = _currentIndex == 0;

          // Load values when position changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Only update if the field is empty or if we navigated
            if (_istBestandController.text.isEmpty &&
                position.gezaehlt &&
                position.istBestand != null) {
              _istBestandController.text =
                  position.istBestand!.toStringAsFixed(
                position.istBestand! ==
                        position.istBestand!.roundToDouble()
                    ? 0
                    : 2,
              );
            }
            if (_bemerkungController.text.isEmpty &&
                position.bemerkung != null) {
              _bemerkungController.text = position.bemerkung!;
            }
          });

          // Total progress (from all positions)
          final totalGezaehlt =
              allPositionen.where((p) => p.gezaehlt).length;
          final totalGesamt = allPositionen.length;

          return Column(
            children: [
              // ─── Progress Bar ───
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Position ${_currentIndex + 1} von ${positionen.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'Gesamt: $totalGezaehlt / $totalGesamt',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalGesamt > 0
                            ? totalGezaehlt / totalGesamt
                            : 0,
                        backgroundColor:
                            colorScheme.surfaceContainerHighest,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Position Content ───
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Artikel Name (large)
                      Text(
                        position.artikelBezeichnung ??
                            'Unbekannter Artikel',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Artikelnummer + Lagerort
                      Row(
                        children: [
                          if (position.artikelArtikelnummer != null &&
                              position
                                  .artikelArtikelnummer!.isNotEmpty) ...[
                            Icon(Icons.tag,
                                size: 16,
                                color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              position.artikelArtikelnummer!,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Icon(Icons.warehouse_outlined,
                              size: 16,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            position.lagerortBezeichnung ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Soll-Bestand (prominent)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.primary
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Soll-Bestand',
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${position.sollBestand.toStringAsFixed(position.sollBestand == position.sollBestand.roundToDouble() ? 0 : 2)} ${position.artikelEinheit ?? 'Stk'}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Ist-Bestand Input (large)
                      Text(
                        'Ist-Bestand',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _istBestandController,
                        focusNode: _istBestandFocus,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.,]'),
                          ),
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                          ),
                          suffixText: position.artikelEinheit ?? 'Stk',
                          suffixStyle: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                        onFieldSubmitted: (_) {
                          if (isLast) {
                            _finish(positionen);
                          } else {
                            _goNext(positionen);
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      // Bemerkung (optional)
                      Text(
                        'Bemerkung (optional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _bemerkungController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'z.B. beschaedigt, abgelaufen...',
                        ),
                      ),

                      // Status indicator if already counted
                      if (position.gezaehlt) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppStatusColors.success
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppStatusColors.success,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Bereits gezaehlt',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppStatusColors.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ─── Navigation Buttons ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: colorScheme.outlineVariant),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Zurueck button
                      if (!isFirst)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isSaving
                                ? null
                                : () => _goBack(positionen),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Zurueck'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 52),
                            ),
                          ),
                        ),
                      if (!isFirst) const SizedBox(width: 12),

                      // Weiter / Fertig button
                      Expanded(
                        flex: isFirst ? 1 : 1,
                        child: isLast
                            ? FilledButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : () => _finish(positionen),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.check),
                                label: const Text('Fertig'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                ),
                              )
                            : FilledButton.icon(
                                onPressed: _isSaving
                                    ? null
                                    : () async {
                                        final saved = await _saveCurrentCount(
                                            positionen[_currentIndex]);
                                        if (!saved) return;
                                        ref.invalidate(
                                            inventurPositionenProvider(
                                                widget.inventurId));
                                        setState(() {
                                          _currentIndex++;
                                          _istBestandController.clear();
                                          _bemerkungController.clear();
                                        });
                                        // Load values for next position after rebuild
                                        Future.delayed(
                                            const Duration(milliseconds: 50),
                                            () {
                                          if (mounted) {
                                            _istBestandFocus.requestFocus();
                                          }
                                        });
                                      },
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward),
                                label: const Text('Weiter'),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 52),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
