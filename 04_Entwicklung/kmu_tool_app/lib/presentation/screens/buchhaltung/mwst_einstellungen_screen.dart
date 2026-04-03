import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/mwst_einstellung.dart';
import 'package:kmu_tool_app/data/repositories/mwst_repository.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

final _einstellungProvider = FutureProvider<MwstEinstellung?>((ref) async {
  return MwstRepository().getEinstellung();
});

class MwstEinstellungenScreen extends ConsumerStatefulWidget {
  const MwstEinstellungenScreen({super.key});

  @override
  ConsumerState<MwstEinstellungenScreen> createState() =>
      _MwstEinstellungenScreenState();
}

class _MwstEinstellungenScreenState
    extends ConsumerState<MwstEinstellungenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mwstNummerController = TextEditingController();
  final _sss1Controller = TextEditingController();
  final _sss1BezController = TextEditingController();
  final _sss2Controller = TextEditingController();
  final _sss2BezController = TextEditingController();

  String _methode = 'effektiv';
  String _abrechnungsperiode = 'halbjaehrlich';
  bool _vereinbartesEntgelt = true;
  DateTime? _mwstPflichtigSeit;
  bool _isSaving = false;
  String? _existingId;

  @override
  void dispose() {
    _mwstNummerController.dispose();
    _sss1Controller.dispose();
    _sss1BezController.dispose();
    _sss2Controller.dispose();
    _sss2BezController.dispose();
    super.dispose();
  }

  void _loadExisting(MwstEinstellung e) {
    _existingId = e.id;
    _methode = e.methode;
    _abrechnungsperiode = e.abrechnungsperiode;
    _mwstNummerController.text = e.mwstNummer ?? '';
    _sss1Controller.text =
        e.saldosteuersatz1?.toStringAsFixed(2) ?? '';
    _sss1BezController.text = e.saldosteuersatz1Bez ?? '';
    _sss2Controller.text =
        e.saldosteuersatz2?.toStringAsFixed(2) ?? '';
    _sss2BezController.text = e.saldosteuersatz2Bez ?? '';
    _vereinbartesEntgelt = e.vereinbartesEntgelt;
    _mwstPflichtigSeit = e.mwstPflichtigSeit;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _mwstPflichtigSeit ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2099),
      locale: const Locale('de', 'CH'),
      useRootNavigator: false,
    );
    if (picked != null) {
      setState(() => _mwstPflichtigSeit = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final userId = await BetriebService.getDataOwnerId();
      final einstellung = MwstEinstellung(
        id: _existingId ?? const Uuid().v4(),
        userId: userId,
        methode: _methode,
        abrechnungsperiode: _abrechnungsperiode,
        saldosteuersatz1: _methode == 'saldosteuersatz'
            ? double.tryParse(_sss1Controller.text)
            : null,
        saldosteuersatz1Bez: _methode == 'saldosteuersatz'
            ? _sss1BezController.text.trim().isEmpty
                ? null
                : _sss1BezController.text.trim()
            : null,
        saldosteuersatz2: _methode == 'saldosteuersatz'
            ? double.tryParse(_sss2Controller.text)
            : null,
        saldosteuersatz2Bez: _methode == 'saldosteuersatz'
            ? _sss2BezController.text.trim().isEmpty
                ? null
                : _sss2BezController.text.trim()
            : null,
        mwstNummer: _mwstNummerController.text.trim().isEmpty
            ? null
            : _mwstNummerController.text.trim(),
        mwstPflichtigSeit: _mwstPflichtigSeit,
        vereinbartesEntgelt: _vereinbartesEntgelt,
      );

      await MwstRepository().saveEinstellung(einstellung);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MWST-Einstellungen gespeichert'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(_einstellungProvider);
        context.pop();
      }
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final einstellungAsync = ref.watch(_einstellungProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('MWST-Einstellungen'),
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
      body: einstellungAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
        data: (existing) {
          // Nur einmal laden
          if (existing != null && _existingId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _loadExisting(existing));
            });
          }
          return _buildForm();
        },
      ),
    );
  }

  Widget _buildForm() {
    final dateFmt = DateFormat('dd.MM.yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── MWST-Nummer ──
            TextFormField(
              controller: _mwstNummerController,
              decoration: const InputDecoration(
                labelText: 'MWST-Nummer',
                hintText: 'CHE-123.456.789 MWST',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 16),

            // ── Pflichtig seit ──
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'MWST-pflichtig seit',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _mwstPflichtigSeit != null
                      ? dateFmt.format(_mwstPflichtigSeit!)
                      : 'Datum waehlen',
                  style: TextStyle(
                    color: _mwstPflichtigSeit != null
                        ? null
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Abrechnungsmethode ──
            const Text(
              'ABRECHNUNGSMETHODE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            _MethodeCard(
              title: 'Effektive Methode',
              subtitle: 'Umsatzsteuer - Vorsteuer = Zahllast\n'
                  'Vorteil bei hohem Materialanteil (> 45%)',
              isSelected: _methode == 'effektiv',
              onTap: () => setState(() => _methode = 'effektiv'),
            ),
            const SizedBox(height: 8),
            _MethodeCard(
              title: 'Saldosteuersatz-Methode',
              subtitle: 'Bruttoumsatz x SSS = Zahllast\n'
                  'Weniger Aufwand, ideal fuer Handwerksbetriebe',
              isSelected: _methode == 'saldosteuersatz',
              onTap: () => setState(() => _methode = 'saldosteuersatz'),
            ),
            const SizedBox(height: 24),

            // ── SSS-Einstellungen (nur bei Saldosteuersatz) ──
            if (_methode == 'saldosteuersatz') ...[
              const Text(
                'SALDOSTEUERSAETZE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Branchenauswahl als Chips
              Text(
                'Branche waehlen:',
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: MwstEinstellung.branchenSaetze.entries.map((e) {
                  final isSelected =
                      _sss1BezController.text == e.key;
                  return ActionChip(
                    label: Text(
                      '${e.key} (${e.value}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                    backgroundColor: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    onPressed: () {
                      setState(() {
                        _sss1Controller.text = e.value.toStringAsFixed(2);
                        _sss1BezController.text = e.key;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 1. Saldosteuersatz
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _sss1Controller,
                      decoration: const InputDecoration(
                        labelText: 'SSS 1 (%)',
                        hintText: '5.30',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) {
                        if (_methode != 'saldosteuersatz') return null;
                        if (v == null || v.isEmpty) {
                          return 'Pflichtfeld';
                        }
                        final val = double.tryParse(v);
                        if (val == null || val <= 0 || val > 10) {
                          return '0.1 - 10.0%';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _sss1BezController,
                      decoration: const InputDecoration(
                        labelText: 'Branche',
                        hintText: 'z.B. Sanitaerinstallation',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Saldosteuersatz (optional)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _sss2Controller,
                      decoration: const InputDecoration(
                        labelText: 'SSS 2 (%) optional',
                        hintText: '2.80',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _sss2BezController,
                      decoration: const InputDecoration(
                        labelText: 'Nebenbranche',
                        hintText: 'z.B. Gartenarbeiten',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Neue 10%-Regel ab 2025: Jede Taetigkeit > 10% Umsatz '
                'braucht eigenen SSS.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
            ],

            // ── Abrechnungsperiode ──
            const Text(
              'ABRECHNUNGSPERIODE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'quartalsweise',
                  label: Text('Quartal'),
                ),
                ButtonSegment(
                  value: 'halbjaehrlich',
                  label: Text('Halbjahr'),
                ),
                ButtonSegment(
                  value: 'jaehrlich',
                  label: Text('Jahr'),
                ),
              ],
              selected: {_abrechnungsperiode},
              onSelectionChanged: (s) =>
                  setState(() => _abrechnungsperiode = s.first),
            ),
            const SizedBox(height: 8),
            if (_abrechnungsperiode == 'jaehrlich')
              Text(
                'Jaehrliche Abrechnung: max. CHF 5\'005\'000 Umsatz, '
                'max. CHF 108\'000 Steuerschuld.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 24),

            // ── Vereinbartes/Vereinnahmtes Entgelt ──
            SwitchListTile(
              title: const Text('Vereinbartes Entgelt'),
              subtitle: Text(
                _vereinbartesEntgelt
                    ? 'Abrechnung nach Rechnungsdatum (Standard)'
                    : 'Abrechnung nach Zahlungseingang',
                style: const TextStyle(fontSize: 13),
              ),
              value: _vereinbartesEntgelt,
              onChanged: (v) => setState(() => _vereinbartesEntgelt = v),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _MethodeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodeCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
