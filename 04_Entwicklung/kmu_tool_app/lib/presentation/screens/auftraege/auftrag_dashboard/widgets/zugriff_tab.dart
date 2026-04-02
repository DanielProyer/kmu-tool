import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/auftrag_zugriff.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_zugriff_repository.dart';
import 'package:kmu_tool_app/presentation/providers/auftrag_dashboard_provider.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class ZugriffTab extends ConsumerStatefulWidget {
  final String auftragId;

  const ZugriffTab({super.key, required this.auftragId});

  @override
  ConsumerState<ZugriffTab> createState() => _ZugriffTabState();
}

class _ZugriffTabState extends ConsumerState<ZugriffTab> {
  final _emailController = TextEditingController();
  String _selectedRolle = 'standard';
  bool _isAdding = false;

  Future<void> _addZugriff() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isAdding = true);
    try {
      // User-ID anhand Email finden
      final userId = SupabaseService.client.auth.currentUser!.id;

      // Hinweis: In der Praxis würde man hier eine Edge Function nutzen,
      // die den User anhand der Email sucht. Für den MVP speichern wir
      // die Email als user_id Platzhalter – wird später mit Invite-System ersetzt.
      await AuftragZugriffRepository.create(AuftragZugriff(
        id: '',
        auftragId: widget.auftragId,
        userId: userId, // Platzhalter
        ownerUserId: userId,
        rolle: _selectedRolle,
      ));

      _emailController.clear();
      ref.invalidate(auftragZugriffeProvider(widget.auftragId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Zugriff hinzugefuegt'),
            backgroundColor: AppStatusColors.success,
          ),
        );
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
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final zugriffeAsync =
        ref.watch(auftragZugriffeProvider(widget.auftragId));
    final theme = Theme.of(context);

    return Column(
      children: [
        // Neuer Zugriff
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Zugriff vergeben',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'E-Mail-Adresse',
                  isDense: true,
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'vollzugriff',
                          label: Text('Voll'),
                          icon: Icon(Icons.admin_panel_settings, size: 16),
                        ),
                        ButtonSegment(
                          value: 'standard',
                          label: Text('Standard'),
                          icon: Icon(Icons.person, size: 16),
                        ),
                        ButtonSegment(
                          value: 'kunde',
                          label: Text('Kunde'),
                          icon: Icon(Icons.person_outline, size: 16),
                        ),
                      ],
                      selected: {_selectedRolle},
                      onSelectionChanged: (s) =>
                          setState(() => _selectedRolle = s.first),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isAdding ? null : _addZugriff,
                    icon: _isAdding
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Zugriffe-Liste
        Expanded(
          child: zugriffeAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Fehler: $e')),
            data: (zugriffe) {
              if (zugriffe.isEmpty) {
                return const Center(
                  child: Text('Keine Zugriffe vergeben'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: zugriffe.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final zugriff = zugriffe[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          _rolleColor(zugriff.rolle).withValues(alpha: 0.12),
                      child: Icon(
                        _rolleIcon(zugriff.rolle),
                        color: _rolleColor(zugriff.rolle),
                        size: 20,
                      ),
                    ),
                    title: Text(zugriff.userId.substring(0, 8)),
                    subtitle: Text(zugriff.rolleLabel),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: AppStatusColors.error),
                      onPressed: () async {
                        await AuftragZugriffRepository.delete(zugriff.id);
                        ref.invalidate(
                            auftragZugriffeProvider(widget.auftragId));
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Color _rolleColor(String rolle) {
    switch (rolle) {
      case 'vollzugriff':
        return AppStatusColors.warning;
      case 'standard':
        return AppStatusColors.info;
      case 'kunde':
        return AppStatusColors.success;
      default:
        return AppStatusColors.storniert;
    }
  }

  IconData _rolleIcon(String rolle) {
    switch (rolle) {
      case 'vollzugriff':
        return Icons.admin_panel_settings;
      case 'standard':
        return Icons.person;
      case 'kunde':
        return Icons.person_outline;
      default:
        return Icons.person;
    }
  }
}
