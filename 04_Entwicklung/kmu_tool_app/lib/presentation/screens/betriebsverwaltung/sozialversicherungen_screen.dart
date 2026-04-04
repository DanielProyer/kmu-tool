import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/sozialversicherung.dart';
import 'package:kmu_tool_app/data/repositories/sozialversicherung_repository.dart';
import 'package:kmu_tool_app/presentation/providers/betriebsverwaltung_provider.dart';

class SozialversicherungenScreen extends ConsumerStatefulWidget {
  const SozialversicherungenScreen({super.key});

  @override
  ConsumerState<SozialversicherungenScreen> createState() =>
      _SozialversicherungenScreenState();
}

class _SozialversicherungenScreenState
    extends ConsumerState<SozialversicherungenScreen> {
  final _formKey = GlobalKey<FormState>();

  // AHV
  final _ahvSatzAgController = TextEditingController();
  final _ahvSatzAnController = TextEditingController();
  // ALV
  final _alvSatzAgController = TextEditingController();
  final _alvSatzAnController = TextEditingController();
  final _alvGrenzeController = TextEditingController();
  final _alv2SatzController = TextEditingController();
  // UVG
  final _uvgBuSatzController = TextEditingController();
  final _uvgNbuSatzController = TextEditingController();
  final _uvgMaxController = TextEditingController();
  // KTG
  final _ktgSatzAgController = TextEditingController();
  final _ktgSatzAnController = TextEditingController();
  // BVG
  final _bvgAnbieterController = TextEditingController();
  final _bvgVertragNrController = TextEditingController();
  final _bvgKoordController = TextEditingController();
  final _bvgEintrittsController = TextEditingController();
  final _bvgMaxLohnController = TextEditingController();
  final _bvgSatz2534Controller = TextEditingController();
  final _bvgSatz3544Controller = TextEditingController();
  final _bvgSatz4554Controller = TextEditingController();
  final _bvgSatz5564Controller = TextEditingController();
  final _bvgAgAnteilController = TextEditingController();
  // FAK
  final _kinderzulageController = TextEditingController();
  final _ausbildungszulageController = TextEditingController();
  // QST
  bool _quellensteuerAktiv = false;

  bool _isLoading = false;
  Sozialversicherung? _existing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final sv = await SozialversicherungRepository.get();
      if (mounted) {
        _existing = sv;
        _ahvSatzAgController.text = sv.ahvSatzAg.toString();
        _ahvSatzAnController.text = sv.ahvSatzAn.toString();
        _alvSatzAgController.text = sv.alvSatzAg.toString();
        _alvSatzAnController.text = sv.alvSatzAn.toString();
        _alvGrenzeController.text = sv.alvGrenze.toStringAsFixed(0);
        _alv2SatzController.text = sv.alv2Satz.toString();
        _uvgBuSatzController.text = sv.uvgBuSatz.toString();
        _uvgNbuSatzController.text = sv.uvgNbuSatz.toString();
        _uvgMaxController.text = sv.uvgMaxVerdienst.toStringAsFixed(0);
        _ktgSatzAgController.text = sv.ktgSatzAg.toString();
        _ktgSatzAnController.text = sv.ktgSatzAn.toString();
        _bvgAnbieterController.text = sv.bvgAnbieter ?? '';
        _bvgVertragNrController.text = sv.bvgVertragNr ?? '';
        _bvgKoordController.text = sv.bvgKoordinationsabzug.toStringAsFixed(0);
        _bvgEintrittsController.text = sv.bvgEintrittsschwelle.toStringAsFixed(0);
        _bvgMaxLohnController.text = sv.bvgMaxVersicherterLohn.toStringAsFixed(0);
        _bvgSatz2534Controller.text = sv.bvgSatz2534.toString();
        _bvgSatz3544Controller.text = sv.bvgSatz3544.toString();
        _bvgSatz4554Controller.text = sv.bvgSatz4554.toString();
        _bvgSatz5564Controller.text = sv.bvgSatz5564.toString();
        _bvgAgAnteilController.text = sv.bvgAgAnteilProzent.toString();
        _kinderzulageController.text = sv.kinderzulageBetrag.toStringAsFixed(0);
        _ausbildungszulageController.text =
            sv.ausbildungszulageBetrag.toStringAsFixed(0);
        _quellensteuerAktiv = sv.quellensteuerAktiv;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppStatusColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _parseDouble(String text) =>
      double.tryParse(text.replaceAll("'", '').replaceAll(',', '.')) ?? 0;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existing == null) return;

    setState(() => _isLoading = true);
    try {
      final sv = Sozialversicherung(
        id: _existing!.id,
        userId: _existing!.userId,
        ahvSatzAg: _parseDouble(_ahvSatzAgController.text),
        ahvSatzAn: _parseDouble(_ahvSatzAnController.text),
        alvSatzAg: _parseDouble(_alvSatzAgController.text),
        alvSatzAn: _parseDouble(_alvSatzAnController.text),
        alvGrenze: _parseDouble(_alvGrenzeController.text),
        alv2Satz: _parseDouble(_alv2SatzController.text),
        uvgBuSatz: _parseDouble(_uvgBuSatzController.text),
        uvgNbuSatz: _parseDouble(_uvgNbuSatzController.text),
        uvgMaxVerdienst: _parseDouble(_uvgMaxController.text),
        ktgSatzAg: _parseDouble(_ktgSatzAgController.text),
        ktgSatzAn: _parseDouble(_ktgSatzAnController.text),
        bvgAnbieter: _bvgAnbieterController.text.trim().isEmpty
            ? null
            : _bvgAnbieterController.text.trim(),
        bvgVertragNr: _bvgVertragNrController.text.trim().isEmpty
            ? null
            : _bvgVertragNrController.text.trim(),
        bvgKoordinationsabzug: _parseDouble(_bvgKoordController.text),
        bvgEintrittsschwelle: _parseDouble(_bvgEintrittsController.text),
        bvgMaxVersicherterLohn: _parseDouble(_bvgMaxLohnController.text),
        bvgSatz2534: _parseDouble(_bvgSatz2534Controller.text),
        bvgSatz3544: _parseDouble(_bvgSatz3544Controller.text),
        bvgSatz4554: _parseDouble(_bvgSatz4554Controller.text),
        bvgSatz5564: _parseDouble(_bvgSatz5564Controller.text),
        bvgAgAnteilProzent: _parseDouble(_bvgAgAnteilController.text),
        kinderzulageBetrag: _parseDouble(_kinderzulageController.text),
        ausbildungszulageBetrag: _parseDouble(_ausbildungszulageController.text),
        quellensteuerAktiv: _quellensteuerAktiv,
      );

      await SozialversicherungRepository.save(sv);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Gespeichert'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(sozialversicherungProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e'), backgroundColor: AppStatusColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _ahvSatzAgController.dispose();
    _ahvSatzAnController.dispose();
    _alvSatzAgController.dispose();
    _alvSatzAnController.dispose();
    _alvGrenzeController.dispose();
    _alv2SatzController.dispose();
    _uvgBuSatzController.dispose();
    _uvgNbuSatzController.dispose();
    _uvgMaxController.dispose();
    _ktgSatzAgController.dispose();
    _ktgSatzAnController.dispose();
    _bvgAnbieterController.dispose();
    _bvgVertragNrController.dispose();
    _bvgKoordController.dispose();
    _bvgEintrittsController.dispose();
    _bvgMaxLohnController.dispose();
    _bvgSatz2534Controller.dispose();
    _bvgSatz3544Controller.dispose();
    _bvgSatz4554Controller.dispose();
    _bvgSatz5564Controller.dispose();
    _bvgAgAnteilController.dispose();
    _kinderzulageController.dispose();
    _ausbildungszulageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozialversicherungen'),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _save,
            icon: _isLoading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check),
            label: const Text('Speichern'),
          ),
        ],
      ),
      body: _isLoading && _existing == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionHeader('AHV / IV / EO'),
                    const SizedBox(height: 12),
                    _percentRow('AG-Satz', _ahvSatzAgController,
                        'AN-Satz', _ahvSatzAnController),

                    const SizedBox(height: 24),
                    _sectionHeader('ALV'),
                    const SizedBox(height: 12),
                    _percentRow('AG-Satz', _alvSatzAgController,
                        'AN-Satz', _alvSatzAnController),
                    const SizedBox(height: 12),
                    _amountField('Maximal versicherter Lohn', _alvGrenzeController),
                    const SizedBox(height: 12),
                    _percentField('ALV2 Solidaritaetssatz', _alv2SatzController),

                    const SizedBox(height: 24),
                    _sectionHeader('UVG'),
                    const SizedBox(height: 12),
                    _percentRow('BU-Satz (AG)', _uvgBuSatzController,
                        'NBU-Satz (AN)', _uvgNbuSatzController),
                    const SizedBox(height: 12),
                    _amountField('UVG Max. Verdienst', _uvgMaxController),

                    const SizedBox(height: 24),
                    _sectionHeader('KTG'),
                    const SizedBox(height: 12),
                    _percentRow('AG-Satz', _ktgSatzAgController,
                        'AN-Satz', _ktgSatzAnController),

                    const SizedBox(height: 24),
                    _sectionHeader('BVG (2. SAEULE)'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bvgAnbieterController,
                      decoration: const InputDecoration(
                        labelText: 'Anbieter',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bvgVertragNrController,
                      decoration: const InputDecoration(
                        labelText: 'Vertrag-Nr.',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _amountField('Koordinationsabzug', _bvgKoordController),
                    const SizedBox(height: 12),
                    _amountField('Eintrittsschwelle', _bvgEintrittsController),
                    const SizedBox(height: 12),
                    _amountField('Max. versicherter Lohn', _bvgMaxLohnController),
                    const SizedBox(height: 12),
                    _percentRow('25-34 Jahre', _bvgSatz2534Controller,
                        '35-44 Jahre', _bvgSatz3544Controller),
                    const SizedBox(height: 12),
                    _percentRow('45-54 Jahre', _bvgSatz4554Controller,
                        '55-64 Jahre', _bvgSatz5564Controller),
                    const SizedBox(height: 12),
                    _percentField('AG-Anteil (%)', _bvgAgAnteilController),

                    const SizedBox(height: 24),
                    _sectionHeader('KINDERZULAGEN (FAK)'),
                    const SizedBox(height: 12),
                    _amountField('Kinderzulage / Monat', _kinderzulageController),
                    const SizedBox(height: 12),
                    _amountField('Ausbildungszulage / Monat',
                        _ausbildungszulageController),

                    const SizedBox(height: 24),
                    _sectionHeader('QUELLENSTEUER'),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Quellensteuer aktiv'),
                      subtitle: const Text(
                          'Fuer auslaendische Mitarbeiter ohne C-Bewilligung'),
                      value: _quellensteuerAktiv,
                      onChanged: (v) => setState(() => _quellensteuerAktiv = v),
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

  Widget _percentRow(String label1, TextEditingController c1,
      String label2, TextEditingController c2) {
    return Row(
      children: [
        Expanded(child: _percentField(label1, c1)),
        const SizedBox(width: 12),
        Expanded(child: _percentField(label2, c2)),
      ],
    );
  }

  Widget _percentField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: '%',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _amountField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'CHF',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }
}
