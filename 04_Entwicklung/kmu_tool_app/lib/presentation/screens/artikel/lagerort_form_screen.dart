import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kmu_tool_app/data/models/lagerort.dart';
import 'package:kmu_tool_app/data/repositories/lagerort_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class LagerortFormScreen extends ConsumerStatefulWidget {
  final String? lagerortId;

  const LagerortFormScreen({super.key, this.lagerortId});

  @override
  ConsumerState<LagerortFormScreen> createState() =>
      _LagerortFormScreenState();
}

class _LagerortFormScreenState extends ConsumerState<LagerortFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bezeichnungController = TextEditingController();
  final _sortierungController = TextEditingController(text: '0');

  String _typ = 'lager';
  bool _istStandard = false;

  bool _isLoading = false;
  bool _isEdit = false;
  Lagerort? _existingLagerort;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.lagerortId != null;
    if (_isEdit) {
      _loadLagerort();
    }
  }

  Future<void> _loadLagerort() async {
    setState(() => _isLoading = true);
    try {
      final lagerort = await LagerortRepository.getById(widget.lagerortId!);
      if (lagerort != null && mounted) {
        _existingLagerort = lagerort;
        _bezeichnungController.text = lagerort.bezeichnung;
        _typ = lagerort.typ;
        _istStandard = lagerort.istStandard;
        _sortierungController.text = lagerort.sortierung.toString();
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
      final id = _isEdit
          ? _existingLagerort!.id
          : const Uuid().v4();
      final userId = _isEdit
          ? _existingLagerort!.userId
          : SupabaseService.currentUser!.id;

      final lagerort = Lagerort(
        id: id,
        userId: userId,
        bezeichnung: _bezeichnungController.text.trim(),
        typ: _typ,
        istStandard: _istStandard,
        sortierung: int.tryParse(_sortierungController.text.trim()) ?? 0,
      );

      await LagerortRepository.save(lagerort);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEdit ? 'Lagerort aktualisiert' : 'Lagerort erstellt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(lagerortListProvider);
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
    _bezeichnungController.dispose();
    _sortierungController.dispose();
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
              : context.go('/lagerorte'),
        ),
        title: Text(_isEdit ? 'Lagerort bearbeiten' : 'Neuer Lagerort'),
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
      body: _isLoading && _isEdit && _existingLagerort == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Bezeichnung ───
                    TextFormField(
                      controller: _bezeichnungController,
                      decoration: const InputDecoration(
                        labelText: 'Bezeichnung *',
                        prefixIcon: Icon(Icons.warehouse_outlined),
                        hintText: 'z.B. Hauptlager, Transporter 1',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pflichtfeld';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Typ Dropdown ───
                    DropdownButtonFormField<String>(
                      value: _typ,
                      decoration: const InputDecoration(
                        labelText: 'Typ',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'lager', child: Text('Lager')),
                        DropdownMenuItem(
                            value: 'fahrzeug', child: Text('Fahrzeug')),
                        DropdownMenuItem(
                            value: 'baustelle',
                            child: Text('Baustelle')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _typ = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // ─── Standard Switch ───
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Standard-Lagerort'),
                      subtitle: const Text(
                        'Wird als Vorgabe bei neuen Warenbewegungen verwendet',
                      ),
                      value: _istStandard,
                      onChanged: (value) =>
                          setState(() => _istStandard = value),
                    ),
                    const SizedBox(height: 16),

                    // ─── Sortierung ───
                    TextFormField(
                      controller: _sortierungController,
                      decoration: const InputDecoration(
                        labelText: 'Sortierung',
                        prefixIcon: Icon(Icons.sort),
                        hintText: 'Reihenfolge in Listen (0 = zuerst)',
                      ),
                      keyboardType: TextInputType.number,
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
