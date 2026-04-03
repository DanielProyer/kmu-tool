import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/local/artikel_local_export.dart';
import 'package:kmu_tool_app/data/repositories/artikel_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/presentation/providers/dashboard_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/repositories/artikel_lieferant_repository.dart';
import 'package:kmu_tool_app/presentation/widgets/lieferant_auswahl_dialog.dart';

class ArtikelFormScreen extends ConsumerStatefulWidget {
  final String? artikelId;

  const ArtikelFormScreen({super.key, this.artikelId});

  @override
  ConsumerState<ArtikelFormScreen> createState() => _ArtikelFormScreenState();
}

class _ArtikelFormScreenState extends ConsumerState<ArtikelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _artikelNrController = TextEditingController();
  final _bezeichnungController = TextEditingController();
  final _einkaufspreisController = TextEditingController();
  final _verkaufspreisController = TextEditingController();
  final _mindestbestandController = TextEditingController();
  final _notizenController = TextEditingController();

  String _kategorie = 'material';
  String? _einheit = 'Stk';
  String? _materialTyp = 'material';

  bool _isLoading = false;
  bool _isEdit = false;
  ArtikelLocal? _existingArtikel;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.artikelId != null;
    if (_isEdit) {
      _loadArtikel();
    }
  }

  Future<void> _loadArtikel() async {
    setState(() => _isLoading = true);
    try {
      final artikel = await ArtikelRepository.getById(widget.artikelId!);
      if (artikel != null && mounted) {
        _existingArtikel = artikel;
        _artikelNrController.text = artikel.artikelNr ?? '';
        _bezeichnungController.text = artikel.bezeichnung;
        _kategorie = artikel.kategorie;
        _einheit = artikel.einheit ?? 'Stk';
        _materialTyp = artikel.materialTyp ?? 'material';
        _einkaufspreisController.text =
            artikel.einkaufspreis > 0
                ? artikel.einkaufspreis.toStringAsFixed(2)
                : '';
        _verkaufspreisController.text =
            artikel.verkaufspreis > 0
                ? artikel.verkaufspreis.toStringAsFixed(2)
                : '';
        _mindestbestandController.text =
            artikel.mindestbestand != null
                ? artikel.mindestbestand!.toStringAsFixed(0)
                : '';
        _notizenController.text = artikel.notizen ?? '';
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
      final artikel = _existingArtikel ?? ArtikelLocal();

      if (!_isEdit) {
        artikel.serverId = const Uuid().v4();
        artikel.userId = await BetriebService.getDataOwnerId();
      }

      artikel.artikelNr = _artikelNrController.text.trim().isEmpty
          ? null
          : _artikelNrController.text.trim();
      artikel.bezeichnung = _bezeichnungController.text.trim();
      artikel.kategorie = _kategorie;
      artikel.einheit = _einheit;
      artikel.materialTyp = _materialTyp;
      artikel.einkaufspreis =
          double.tryParse(_einkaufspreisController.text.trim()) ?? 0;
      artikel.verkaufspreis =
          double.tryParse(_verkaufspreisController.text.trim()) ?? 0;
      artikel.mindestbestand =
          double.tryParse(_mindestbestandController.text.trim());
      artikel.notizen = _notizenController.text.trim().isEmpty
          ? null
          : _notizenController.text.trim();

      await ArtikelRepository.save(artikel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Artikel aktualisiert' : 'Artikel erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(artikelListProvider);
        ref.invalidate(dashboardProvider);
        if (_isEdit) {
          ref.invalidate(artikelProvider(widget.artikelId!));
        }
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
    _artikelNrController.dispose();
    _bezeichnungController.dispose();
    _einkaufspreisController.dispose();
    _verkaufspreisController.dispose();
    _mindestbestandController.dispose();
    _notizenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/artikel'),
        ),
        title: Text(_isEdit ? 'Artikel bearbeiten' : 'Neuer Artikel'),
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
      body: _isLoading && _isEdit && _existingArtikel == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Artikel-Nr ───
                    TextFormField(
                      controller: _artikelNrController,
                      decoration: const InputDecoration(
                        labelText: 'Artikel-Nr (optional)',
                        prefixIcon: Icon(Icons.tag),
                        hintText: 'z.B. ART-001',
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // ─── Bezeichnung ───
                    TextFormField(
                      controller: _bezeichnungController,
                      decoration: const InputDecoration(
                        labelText: 'Bezeichnung *',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pflichtfeld';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Klassifizierung ───
                    _sectionHeader('KLASSIFIZIERUNG'),
                    const SizedBox(height: 12),

                    // Kategorie Dropdown
                    DropdownButtonFormField<String>(
                      value: _kategorie,
                      decoration: const InputDecoration(
                        labelText: 'Kategorie',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'material', child: Text('Material')),
                        DropdownMenuItem(
                            value: 'werkzeug', child: Text('Werkzeug')),
                        DropdownMenuItem(
                            value: 'verbrauch',
                            child: Text('Verbrauchsmaterial')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _kategorie = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Einheit Dropdown
                    DropdownButtonFormField<String>(
                      value: _einheit,
                      decoration: const InputDecoration(
                        labelText: 'Einheit',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Stk', child: Text('Stk')),
                        DropdownMenuItem(value: 'm', child: Text('m')),
                        DropdownMenuItem(
                            value: 'm\u00B2', child: Text('m\u00B2')),
                        DropdownMenuItem(
                            value: 'm\u00B3', child: Text('m\u00B3')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'l', child: Text('l')),
                        DropdownMenuItem(value: 'Psch', child: Text('Psch')),
                        DropdownMenuItem(value: 'Std', child: Text('Std')),
                      ],
                      onChanged: (value) {
                        setState(() => _einheit = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // MaterialTyp Dropdown
                    DropdownButtonFormField<String>(
                      value: _materialTyp,
                      decoration: const InputDecoration(
                        labelText: 'Materialtyp',
                        prefixIcon: Icon(Icons.label_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'material', child: Text('Material')),
                        DropdownMenuItem(
                            value: 'werkzeug', child: Text('Werkzeug')),
                        DropdownMenuItem(
                            value: 'verbrauch',
                            child: Text('Verbrauchsmaterial')),
                        DropdownMenuItem(
                            value: 'dienstleistung',
                            child: Text('Dienstleistung')),
                      ],
                      onChanged: (value) {
                        setState(() => _materialTyp = value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // ─── Preise ───
                    _sectionHeader('PREISE'),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _einkaufspreisController,
                            decoration: const InputDecoration(
                              labelText: 'EK-Preis (CHF)',
                              prefixIcon:
                                  Icon(Icons.shopping_cart_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _verkaufspreisController,
                            decoration: const InputDecoration(
                              labelText: 'VK-Preis (CHF)',
                              prefixIcon: Icon(Icons.sell_outlined),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ─── Lager ───
                    _sectionHeader('LAGER'),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _mindestbestandController,
                      decoration: const InputDecoration(
                        labelText: 'Mindestbestand',
                        prefixIcon: Icon(Icons.warning_amber_outlined),
                        hintText: 'Warnung bei Unterschreitung',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),

                    // ─── Lieferanten (nur im Edit-Modus) ───
                    if (_isEdit) ...[
                      Row(
                        children: [
                          Expanded(child: _sectionHeader('LIEFERANTEN')),
                          TextButton.icon(
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Hinzufuegen'),
                            onPressed: () async {
                              final result = await showDialog<bool>(
                                context: context,
                                useRootNavigator: false,
                                builder: (ctx) => LieferantAuswahlDialog(
                                  artikelId: widget.artikelId!,
                                ),
                              );
                              if (result == true) {
                                ref.invalidate(
                                    artikelLieferantenProvider(
                                        widget.artikelId!));
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ref
                          .watch(artikelLieferantenProvider(
                              widget.artikelId!))
                          .when(
                            loading: () => const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2)),
                            error: (e, _) =>
                                Text('Fehler: $e'),
                            data: (lieferanten) {
                              if (lieferanten.isEmpty) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 16),
                                  child: Text(
                                    'Keine Lieferanten verknuepft',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                );
                              }
                              return Column(
                                children: lieferanten
                                    .map((l) => Card(
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .secondary
                                                      .withValues(
                                                          alpha: 0.1),
                                              child: Icon(
                                                Icons
                                                    .local_shipping_outlined,
                                                size: 18,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                            title: Text(
                                              l.lieferantFirma ??
                                                  'Unbekannt',
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                            subtitle: Text(
                                              [
                                                if (l.einkaufspreis !=
                                                    null)
                                                  'EK: CHF ${l.einkaufspreis!.toStringAsFixed(2)}',
                                                if (l.lieferzeitTage !=
                                                    null)
                                                  '${l.lieferzeitTage} Tage',
                                                if (l.istHauptlieferant)
                                                  'Hauptlieferant',
                                              ].join(' | '),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color: AppStatusColors
                                                    .error,
                                                size: 20,
                                              ),
                                              onPressed: () async {
                                                await ArtikelLieferantRepository
                                                    .delete(l.id);
                                                ref.invalidate(
                                                    artikelLieferantenProvider(
                                                        widget
                                                            .artikelId!));
                                              },
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              );
                            },
                          ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Notizen ───
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
