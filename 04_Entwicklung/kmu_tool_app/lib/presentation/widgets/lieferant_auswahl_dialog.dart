import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/artikel_lieferant.dart';
import 'package:kmu_tool_app/data/repositories/artikel_lieferant_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

/// Dialog zum Hinzufuegen/Bearbeiten einer Artikel-Lieferant-Verknuepfung.
class LieferantAuswahlDialog extends ConsumerStatefulWidget {
  final String artikelId;
  final ArtikelLieferant? existing;

  const LieferantAuswahlDialog({
    super.key,
    required this.artikelId,
    this.existing,
  });

  @override
  ConsumerState<LieferantAuswahlDialog> createState() =>
      _LieferantAuswahlDialogState();
}

class _LieferantAuswahlDialogState
    extends ConsumerState<LieferantAuswahlDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ekPreisController = TextEditingController();
  final _lieferzeitController = TextEditingController();
  final _artNrController = TextEditingController();

  String? _selectedLieferantId;
  bool _istHauptlieferant = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _selectedLieferantId = widget.existing!.lieferantId;
      _ekPreisController.text =
          widget.existing!.einkaufspreis?.toStringAsFixed(2) ?? '';
      _lieferzeitController.text =
          widget.existing!.lieferzeitTage?.toString() ?? '';
      _artNrController.text = widget.existing!.lieferantenArtikelNr ?? '';
      _istHauptlieferant = widget.existing!.istHauptlieferant;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLieferantId == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = await BetriebService.getDataOwnerId();
      final al = ArtikelLieferant(
        id: widget.existing?.id ?? const Uuid().v4(),
        userId: widget.existing?.userId ?? userId,
        artikelId: widget.artikelId,
        lieferantId: _selectedLieferantId!,
        einkaufspreis:
            double.tryParse(_ekPreisController.text.trim()),
        lieferzeitTage:
            int.tryParse(_lieferzeitController.text.trim()),
        lieferantenArtikelNr: _artNrController.text.trim().isEmpty
            ? null
            : _artNrController.text.trim(),
        istHauptlieferant: _istHauptlieferant,
      );

      await ArtikelLieferantRepository.save(al);

      if (_istHauptlieferant) {
        await ArtikelLieferantRepository.setHauptlieferant(
          widget.artikelId,
          _selectedLieferantId!,
        );
      }

      if (mounted) Navigator.pop(context, true);
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
    _ekPreisController.dispose();
    _lieferzeitController.dispose();
    _artNrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lieferantenAsync = ref.watch(lieferantenListProvider);
    final isEdit = widget.existing != null;

    return AlertDialog(
      title: Text(
          isEdit ? 'Lieferant bearbeiten' : 'Lieferant hinzufuegen'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Lieferant Dropdown
                lieferantenAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Fehler: $e'),
                  data: (lieferanten) {
                    return DropdownButtonFormField<String>(
                      value: _selectedLieferantId,
                      decoration: const InputDecoration(
                        labelText: 'Lieferant *',
                        prefixIcon: Icon(Icons.local_shipping_outlined),
                      ),
                      isExpanded: true,
                      items: lieferanten.map((l) {
                        return DropdownMenuItem(
                          value: l.id,
                          child: Text(
                            l.firma,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: isEdit
                          ? null
                          : (value) =>
                              setState(() => _selectedLieferantId = value),
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

                // EK-Preis
                TextFormField(
                  controller: _ekPreisController,
                  decoration: const InputDecoration(
                    labelText: 'EK-Preis (CHF)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                // Lieferzeit
                TextFormField(
                  controller: _lieferzeitController,
                  decoration: const InputDecoration(
                    labelText: 'Lieferzeit (Tage)',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Lieferanten-Artikel-Nr
                TextFormField(
                  controller: _artNrController,
                  decoration: const InputDecoration(
                    labelText: 'Lieferanten-Artikel-Nr',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),

                // Hauptlieferant
                SwitchListTile(
                  title: const Text('Hauptlieferant'),
                  subtitle:
                      const Text('Wird fuer Bestellvorschlaege verwendet'),
                  value: _istHauptlieferant,
                  onChanged: (value) =>
                      setState(() => _istHauptlieferant = value),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEdit ? 'Speichern' : 'Hinzufuegen'),
        ),
      ],
    );
  }
}
