import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/bestellung.dart';
import 'package:kmu_tool_app/data/repositories/bestellung_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class BestellungFormScreen extends ConsumerStatefulWidget {
  const BestellungFormScreen({super.key});

  @override
  ConsumerState<BestellungFormScreen> createState() =>
      _BestellungFormScreenState();
}

class _BestellungFormScreenState extends ConsumerState<BestellungFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bemerkungController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');

  String? _selectedLieferantId;
  DateTime _bestellDatum = DateTime.now();
  DateTime? _erwartetesLieferdatum;

  bool _isLoading = false;

  Future<void> _pickDate({required bool isBestellDatum}) async {
    final initialDate =
        isBestellDatum ? _bestellDatum : (_erwartetesLieferdatum ?? DateTime.now());
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('de', 'CH'),
    );

    if (picked != null) {
      setState(() {
        if (isBestellDatum) {
          _bestellDatum = picked;
        } else {
          _erwartetesLieferdatum = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLieferantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte einen Lieferanten auswaehlen'),
          backgroundColor: AppStatusColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bestellNr = await BestellungRepository.nextBestellNr();
      final bestellungId = const Uuid().v4();

      final bestellung = Bestellung(
        id: bestellungId,
        userId: SupabaseService.currentUser!.id,
        lieferantId: _selectedLieferantId!,
        bestellNr: bestellNr,
        status: 'entwurf',
        bestellDatum: _bestellDatum,
        erwartetesLieferdatum: _erwartetesLieferdatum,
        bemerkung: _bemerkungController.text.trim().isEmpty
            ? null
            : _bemerkungController.text.trim(),
      );

      await BestellungRepository.save(bestellung);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bestellung $bestellNr erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(bestellungenListProvider);
        // Navigate to detail screen so user can add positions
        context.pop();
        context.push('/bestellungen/$bestellungId');
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
    _bemerkungController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lieferantenAsync = ref.watch(lieferantenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/bestellungen'),
        ),
        title: const Text('Neue Bestellung'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Lieferant ───
              _sectionHeader('LIEFERANT'),
              const SizedBox(height: 12),

              lieferantenAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (e, _) => Text(
                  'Fehler beim Laden: $e',
                  style: TextStyle(color: AppStatusColors.error),
                ),
                data: (lieferanten) {
                  if (lieferanten.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_shipping_outlined,
                              size: 40,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keine Lieferanten vorhanden',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  context.push('/lieferanten/neu'),
                              child: const Text('Lieferant erstellen'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedLieferantId,
                    decoration: const InputDecoration(
                      labelText: 'Lieferant *',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    items: lieferanten
                        .map((l) => DropdownMenuItem(
                              value: l.id,
                              child: Text(l.firma),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedLieferantId = value);
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
              const SizedBox(height: 24),

              // ─── Daten ───
              _sectionHeader('BESTELLDATEN'),
              const SizedBox(height: 12),

              // Bestelldatum
              InkWell(
                onTap: () => _pickDate(isBestellDatum: true),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Bestelldatum',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    suffixIcon: Icon(Icons.edit_calendar),
                  ),
                  child: Text(
                    _dateFormat.format(_bestellDatum),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Erwartetes Lieferdatum
              InkWell(
                onTap: () => _pickDate(isBestellDatum: false),
                borderRadius: BorderRadius.circular(10),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Erwartetes Lieferdatum (optional)',
                    prefixIcon: const Icon(Icons.event_outlined),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_erwartetesLieferdatum != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(
                                  () => _erwartetesLieferdatum = null);
                            },
                          ),
                        const Icon(Icons.edit_calendar),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  child: Text(
                    _erwartetesLieferdatum != null
                        ? _dateFormat.format(_erwartetesLieferdatum!)
                        : '–',
                    style: TextStyle(
                      fontSize: 16,
                      color: _erwartetesLieferdatum == null
                          ? colorScheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ─── Bemerkung ───
              _sectionHeader('BEMERKUNG'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _bemerkungController,
                decoration: const InputDecoration(
                  labelText: 'Allgemeine Bemerkung',
                  prefixIcon: Icon(Icons.notes_outlined),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                minLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 24),

              // ─── Info ───
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: AppStatusColors.info,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Positionen koennen nach dem Speichern auf der Detailseite hinzugefuegt werden.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
