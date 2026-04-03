import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/data/models/termin.dart';
import 'package:kmu_tool_app/data/repositories/termin_repository.dart';
import 'package:kmu_tool_app/presentation/providers/termin_provider.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class TerminDetailScreen extends ConsumerWidget {
  final String terminId;

  const TerminDetailScreen({super.key, required this.terminId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final terminAsync = ref.watch(terminProvider(terminId));
    final dateFormat = DateFormat('dd.MM.yyyy');

    return terminAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppStatusColors.error),
                const SizedBox(height: 16),
                Text('Fehler beim Laden: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(terminProvider(terminId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (termin) {
        if (termin == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Termin nicht gefunden')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.canPop(context)
                  ? context.pop()
                  : context.go('/kalender'),
            ),
            title: Text(termin.titel),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context
                      .push('/kalender/$terminId/bearbeiten');
                  ref.invalidate(terminProvider(terminId));
                  ref.invalidate(
                      termineByDatumProvider(termin.datum));
                  ref.invalidate(
                      termineByMonatProvider(termin.datum));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _confirmDelete(context, ref, termin);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Loeschen',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header Card ───
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                termin.titel,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700),
                              ),
                            ),
                            _StatusBadge(
                              label: termin.statusLabel,
                              color: _statusColor(termin.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _TypBadge(
                          label: termin.typLabel,
                          color: _typColor(termin.typ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Details ───
                const _SectionHeader(title: 'Details'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Datum',
                          value: dateFormat.format(termin.datum),
                        ),
                        _DetailRow(
                          icon: Icons.access_time_outlined,
                          label: 'Zeit',
                          value: termin.zeitAnzeige.isNotEmpty
                              ? termin.zeitAnzeige
                              : 'Nicht angegeben',
                        ),
                        if (termin.ort != null &&
                            termin.ort!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Ort',
                            value: termin.ort!,
                          ),
                        _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'Typ',
                          value: termin.typLabel,
                        ),
                        _DetailRow(
                          icon: Icons.flag_outlined,
                          label: 'Status',
                          value: termin.statusLabel,
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Beschreibung ───
                if (termin.beschreibung != null &&
                    termin.beschreibung!.isNotEmpty) ...[
                  const _SectionHeader(title: 'Beschreibung'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.notes_outlined,
                              size: 20,
                              color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              termin.beschreibung!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ─── Verknuepfungen ───
                if (termin.kundeId != null ||
                    termin.auftragId != null) ...[
                  const _SectionHeader(title: 'Verknuepfungen'),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Kunde Chip
                        if (termin.kundeId != null)
                          ActionChip(
                            avatar: Icon(
                              Icons.person_outline,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            label: Text(
                              termin.kundeBezeichnung ??
                                  'Kunde',
                            ),
                            onPressed: () {
                              context.push(
                                  '/kunden/${termin.kundeId}');
                            },
                          ),

                        // Auftrag Chip
                        if (termin.auftragId != null)
                          ActionChip(
                            avatar: Icon(
                              Icons.work_outline,
                              size: 18,
                              color: colorScheme.secondary,
                            ),
                            label: Text(
                              termin.auftragBezeichnung ??
                                  'Auftrag',
                            ),
                            onPressed: () {
                              context.push(
                                  '/auftraege/${termin.auftragId}');
                            },
                          ),
                      ],
                    ),
                  ),
                ],

                // ─── Status-Aktionen ───
                if (termin.status != 'erledigt' &&
                    termin.status != 'abgesagt') ...[
                  const _SectionHeader(title: 'Aktionen'),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (termin.status == 'geplant')
                          FilledButton.tonalIcon(
                            onPressed: () => _changeStatus(
                                context, ref, termin, 'bestaetigt'),
                            icon: Icon(Icons.check_circle_outline,
                                color: AppStatusColors.info),
                            label: const Text('Bestaetigen'),
                          ),
                        FilledButton.tonalIcon(
                          onPressed: () => _changeStatus(
                              context, ref, termin, 'erledigt'),
                          icon: Icon(Icons.done_all,
                              color:
                                  AppStatusColors.abgeschlossen),
                          label: const Text('Als erledigt markieren'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _changeStatus(
                              context, ref, termin, 'abgesagt'),
                          icon: Icon(Icons.cancel_outlined,
                              color: AppStatusColors.storniert),
                          label: const Text('Absagen'),
                        ),
                      ],
                    ),
                  ),
                ],

                // ─── Metadaten ───
                if (termin.createdAt != null) ...[
                  const _SectionHeader(title: 'Metadaten'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.add_circle_outline,
                            label: 'Erstellt',
                            value: DateFormat('dd.MM.yyyy HH:mm')
                                .format(termin.createdAt!),
                          ),
                          if (termin.updatedAt != null)
                            _DetailRow(
                              icon: Icons.update,
                              label: 'Aktualisiert',
                              value: DateFormat('dd.MM.yyyy HH:mm')
                                  .format(termin.updatedAt!),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref,
      Termin termin, String newStatus) async {
    try {
      final updated = Termin(
        id: termin.id,
        userId: termin.userId,
        titel: termin.titel,
        beschreibung: termin.beschreibung,
        datum: termin.datum,
        startZeit: termin.startZeit,
        endZeit: termin.endZeit,
        ganztaegig: termin.ganztaegig,
        ort: termin.ort,
        kundeId: termin.kundeId,
        auftragId: termin.auftragId,
        typ: termin.typ,
        status: newStatus,
        farbe: termin.farbe,
      );
      await TerminRepository.save(updated);
      if (context.mounted) {
        final statusLabel = {
          'geplant': 'Geplant',
          'bestaetigt': 'Bestaetigt',
          'erledigt': 'Erledigt',
          'abgesagt': 'Abgesagt',
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status geaendert: ${statusLabel[newStatus] ?? newStatus}'),
            backgroundColor: AppStatusColors.success,
          ),
        );
        ref.invalidate(terminProvider(terminId));
        ref.invalidate(termineByDatumProvider(termin.datum));
        ref.invalidate(termineByMonatProvider(termin.datum));
        ref.invalidate(termineHeuteCountProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Statuswechsel: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Termin termin) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Termin loeschen?'),
        content: const Text(
          'Moechtest du diesen Termin wirklich loeschen? '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppStatusColors.error,
            ),
            child: const Text('Loeschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await TerminRepository.delete(terminId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Termin geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          ref.invalidate(terminProvider(terminId));
          ref.invalidate(termineByDatumProvider(termin.datum));
          ref.invalidate(termineByMonatProvider(termin.datum));
          ref.invalidate(termineHeuteCountProvider);
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Loeschen: $e'),
              backgroundColor: AppStatusColors.error,
            ),
          );
        }
      }
    }
  }

  Color _typColor(String typ) {
    switch (typ) {
      case 'termin':
        return AppStatusColors.info;
      case 'auftrag':
        return AppStatusColors.warning;
      case 'service':
        return AppStatusColors.success;
      case 'erinnerung':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'geplant':
        return AppStatusColors.offen;
      case 'bestaetigt':
        return AppStatusColors.info;
      case 'erledigt':
        return AppStatusColors.abgeschlossen;
      case 'abgesagt':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }
}

// ─── Helper Widgets ───

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant =
        Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: onSurfaceVariant),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style:
                  TextStyle(fontSize: 13, color: onSurfaceVariant),
            ),
          ),
          Expanded(
            child:
                Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TypBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _TypBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
