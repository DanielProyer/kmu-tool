import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/bankverbindung.dart';
import 'package:kmu_tool_app/data/repositories/bankverbindung_repository.dart';
import 'package:kmu_tool_app/presentation/providers/betriebsverwaltung_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

class BankverbindungFormScreen extends ConsumerStatefulWidget {
  final String? bankverbindungId;

  const BankverbindungFormScreen({super.key, this.bankverbindungId});

  @override
  ConsumerState<BankverbindungFormScreen> createState() =>
      _BankverbindungFormScreenState();
}

class _BankverbindungFormScreenState
    extends ConsumerState<BankverbindungFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bezeichnungController = TextEditingController();
  final _ibanController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bicController = TextEditingController();
  bool _istHauptkonto = false;
  bool _isLoading = false;
  bool _isEdit = false;
  Bankverbindung? _existing;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.bankverbindungId != null;
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final item =
          await BankverbindungRepository.getById(widget.bankverbindungId!);
      if (item != null && mounted) {
        _existing = item;
        _bezeichnungController.text = item.bezeichnung;
        _ibanController.text = item.iban;
        _bankNameController.text = item.bankName ?? '';
        _bicController.text = item.bic ?? '';
        _istHauptkonto = item.istHauptkonto;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final userId = _isEdit
          ? _existing!.userId
          : await BetriebService.getDataOwnerId();

      final item = Bankverbindung(
        id: _isEdit ? _existing!.id : const Uuid().v4(),
        userId: userId,
        bezeichnung: _bezeichnungController.text.trim(),
        iban: _ibanController.text.trim(),
        bankName: _bankNameController.text.trim().isEmpty
            ? null
            : _bankNameController.text.trim(),
        bic: _bicController.text.trim().isEmpty
            ? null
            : _bicController.text.trim(),
        istHauptkonto: _istHauptkonto,
      );

      await BankverbindungRepository.save(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Aktualisiert' : 'Erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(bankverbindungenListProvider);
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

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Loeschen?'),
        content: const Text('Bankverbindung wirklich loeschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Loeschen')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await BankverbindungRepository.delete(widget.bankverbindungId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Geloescht'),
              backgroundColor: AppStatusColors.success),
        );
        ref.invalidate(bankverbindungenListProvider);
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
    _bezeichnungController.dispose();
    _ibanController.dispose();
    _bankNameController.dispose();
    _bicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Bankverbindung bearbeiten' : 'Neue Bankverbindung'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Loeschen',
              onPressed: _isLoading ? null : _delete,
            ),
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
      body: _isLoading && _isEdit && _existing == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _bezeichnungController,
                      decoration: const InputDecoration(
                        labelText: 'Bezeichnung *',
                        prefixIcon: Icon(Icons.label_outline),
                        hintText: 'z.B. Hauptkonto, Sparkonto',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ibanController,
                      decoration: const InputDecoration(
                        labelText: 'IBAN *',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                        hintText: 'CH93 0076 2011 6238 5295 7',
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Pflichtfeld' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bankname',
                        prefixIcon: Icon(Icons.account_balance_outlined),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bicController,
                      decoration: const InputDecoration(
                        labelText: 'BIC/SWIFT',
                        prefixIcon: Icon(Icons.swap_horiz),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Hauptkonto'),
                      subtitle:
                          const Text('Wird auf Rechnungen als Standard verwendet'),
                      value: _istHauptkonto,
                      onChanged: (v) => setState(() => _istHauptkonto = v),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
