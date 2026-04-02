import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/config/features.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/local/zeiterfassung_local_export.dart';
import 'package:kmu_tool_app/data/local/rapport_local_export.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_repository.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/presentation/providers/feature_provider.dart';
import 'package:kmu_tool_app/services/rechnung/rechnung_service.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class AuftragDetailScreen extends ConsumerStatefulWidget {
  final String auftragId;

  const AuftragDetailScreen({super.key, required this.auftragId});

  @override
  ConsumerState<AuftragDetailScreen> createState() =>
      _AuftragDetailScreenState();
}

class _AuftragDetailScreenState
    extends ConsumerState<AuftragDetailScreen> {
  final _dateFormat = DateFormat('dd.MM.yyyy');
  KundeLocal? _kunde;
  bool _isCreatingRechnung = false;

  Future<void> _loadKunde(String kundeId) async {
    if (_kunde != null) return;
    try {
      final kunde = await KundeRepository.getById(kundeId);
      if (kunde != null && mounted) {
        setState(() => _kunde = kunde);
      }
    } catch (_) {}
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'offen':
        return AppColors.offen;
      case 'in_arbeit':
        return AppColors.inBearbeitung;
      case 'abgeschlossen':
        return AppColors.abgeschlossen;
      case 'storniert':
        return AppColors.storniert;
      default:
        return AppColors.storniert;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'offen':
        return 'Offen';
      case 'in_arbeit':
        return 'In Arbeit';
      case 'abgeschlossen':
        return 'Abgeschlossen';
      case 'storniert':
        return 'Storniert';
      default:
        return status;
    }
  }

  Future<void> _changeStatus(AuftragLocal auftrag) async {
    final statuses = ['offen', 'in_arbeit', 'abgeschlossen', 'storniert'];
    final labels = {
      'offen': 'Offen',
      'in_arbeit': 'In Arbeit',
      'abgeschlossen': 'Abgeschlossen',
      'storniert': 'Storniert',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Status aendern',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
            const Divider(height: 1),
            ...statuses.map((s) => ListTile(
                  leading: Icon(
                    s == auftrag.status
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: _statusColor(s),
                  ),
                  title: Text(labels[s]!),
                  selected: s == auftrag.status,
                  onTap: () => Navigator.pop(ctx, s),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null && selected != auftrag.status) {
      auftrag.status = selected;
      await AuftragRepository.save(auftrag);
      ref.invalidate(auftragProvider(widget.auftragId));
      ref.invalidate(auftraegeListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Status geaendert zu "${labels[selected]}"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _createRechnung(AuftragLocal auftrag) async {
    setState(() => _isCreatingRechnung = true);
    try {
      final service = RechnungService();
      final rechnung = await service.createFromAuftrag(
        auftrag.serverId ?? auftrag.id.toString(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Rechnung ${rechnung.rechnungsNr} erstellt'),
            backgroundColor: AppColors.success,
          ),
        );
        context.push('/rechnungen/${rechnung.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen der Rechnung: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingRechnung = false);
    }
  }

  String _formatDauer(int? minuten) {
    if (minuten == null || minuten == 0) return '0:00';
    final h = minuten ~/ 60;
    final m = minuten % 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final auftragAsync = ref.watch(auftragProvider(widget.auftragId));
    final zeiterfassungenAsync =
        ref.watch(zeiterfassungenByAuftragProvider(widget.auftragId));
    final rapporteAsync =
        ref.watch(rapporteByAuftragProvider(widget.auftragId));

    return auftragAsync.when(
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
                const Icon(Icons.error_outline,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Fehler: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(auftragProvider(widget.auftragId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (auftrag) {
        if (auftrag == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Auftrag nicht gefunden')),
          );
        }

        // Load Kunde info
        _loadKunde(auftrag.kundeId);

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.canPop(context)
                  ? context.pop()
                  : context.go('/auftraege'),
            ),
            title: Text(auftrag.auftragsNr ?? 'Auftrag'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context.push(
                      '/auftraege/${widget.auftragId}/bearbeiten');
                  ref.invalidate(
                      auftragProvider(widget.auftragId));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'status') {
                    _changeStatus(auftrag);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'status',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 20),
                        SizedBox(width: 8),
                        Text('Status aendern'),
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
                                auftrag.auftragsNr ?? 'Auftrag',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.w700),
                              ),
                            ),
                            _StatusBadge(
                              label: _statusLabel(auftrag.status),
                              color: _statusColor(auftrag.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_kunde != null)
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: 'Kunde',
                            value: _kunde!.firma ??
                                '${_kunde!.vorname ?? ''} ${_kunde!.nachname}'
                                    .trim(),
                          ),
                        if (_kunde?.firma != null &&
                            _kunde!.firma!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Kontakt',
                            value:
                                '${_kunde!.vorname ?? ''} ${_kunde!.nachname}'
                                    .trim(),
                          ),
                        if (auftrag.beschreibung != null &&
                            auftrag.beschreibung!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.description_outlined,
                            label: 'Beschreibung',
                            value: auftrag.beschreibung!,
                          ),
                        if (auftrag.geplantVon != null ||
                            auftrag.geplantBis != null)
                          _InfoRow(
                            icon: Icons.date_range_outlined,
                            label: 'Zeitraum',
                            value: _buildZeitraumText(auftrag),
                          ),
                      ],
                    ),
                  ),
                ),

                // ─── Zeiterfassungen ───
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    'ZEITERFASSUNGEN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                zeiterfassungenAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (zeiterfassungen) {
                    if (zeiterfassungen.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Zeiterfassungen vorhanden',
                          style: TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      );
                    }

                    // Calculate total hours
                    int totalMinuten = 0;
                    for (final ze in zeiterfassungen) {
                      totalMinuten += ze.dauerMinuten ?? 0;
                    }

                    return Card(
                      child: Column(
                        children: [
                          ...zeiterfassungen.map((ze) =>
                              _ZeiterfassungRow(
                                zeiterfassung: ze,
                                dateFormat: _dateFormat,
                                formatDauer: _formatDauer,
                              )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary
                                  .withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(12),
                                bottomRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${_formatDauer(totalMinuten)} Std.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push(
                          '/auftraege/${widget.auftragId}/zeiterfassung/neu');
                      ref.invalidate(zeiterfassungenByAuftragProvider(
                          widget.auftragId));
                    },
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Zeit erfassen'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),

                // ─── Rapporte ───
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'RAPPORTE',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                rapporteAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child:
                            CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (rapporte) {
                    if (rapporte.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Rapporte vorhanden',
                          style: TextStyle(
                              color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Card(
                      child: Column(
                        children: rapporte
                            .map((r) => _RapportRow(
                                  rapport: r,
                                  dateFormat: _dateFormat,
                                  statusColor: _rapportStatusColor(
                                      r.status),
                                  statusLabel: _rapportStatusLabel(
                                      r.status),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await context.push(
                          '/auftraege/${widget.auftragId}/rapport/neu');
                      ref.invalidate(rapporteByAuftragProvider(
                          widget.auftragId));
                    },
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Rapport erstellen'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ),

                // ─── Verknuepfte Offerte ───
                if (auftrag.offerteId != null) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'VERKNUEPFTE OFFERTE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined,
                          color: AppColors.primary),
                      title: Text(
                          'Offerte ${auftrag.offerteId!.substring(0, 8)}...'),
                      subtitle: const Text('Tippen zum Oeffnen'),
                      trailing: const Icon(Icons.chevron_right,
                          color: AppColors.textSecondary),
                      onTap: () {
                        context.push(
                            '/offerten/${auftrag.offerteId}');
                      },
                    ),
                  ),
                ],

                // ─── Dashboard-Button (Premium) ───
                Builder(
                  builder: (context) {
                    final hasDashboard = ref.watch(
                        hasFeatureProvider(AppFeature.auftragDashboard));
                    if (!hasDashboard) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                            '/auftraege/${widget.auftragId}/dashboard'),
                        icon: const Icon(Icons.dashboard_outlined),
                        label: const Text('Auftrag-Dashboard'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                    );
                  },
                ),

                // ─── Rechnung erstellen ───
                if (auftrag.status != 'storniert') ...[
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FilledButton.icon(
                      onPressed: _isCreatingRechnung
                          ? null
                          : () => _createRechnung(auftrag),
                      icon: _isCreatingRechnung
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.receipt_long_outlined),
                      label: const Text('Rechnung erstellen'),
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

  String _buildZeitraumText(AuftragLocal auftrag) {
    final von = auftrag.geplantVon != null
        ? _dateFormat.format(auftrag.geplantVon!)
        : '–';
    final bis = auftrag.geplantBis != null
        ? _dateFormat.format(auftrag.geplantBis!)
        : '–';
    return '$von  –  $bis';
  }

  Color _rapportStatusColor(String status) {
    switch (status) {
      case 'entwurf':
        return AppColors.storniert;
      case 'abgeschlossen':
        return AppColors.abgeschlossen;
      default:
        return AppColors.storniert;
    }
  }

  String _rapportStatusLabel(String status) {
    switch (status) {
      case 'entwurf':
        return 'Entwurf';
      case 'abgeschlossen':
        return 'Abgeschlossen';
      default:
        return status;
    }
  }
}

// ─── Helper Widgets ───

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _ZeiterfassungRow extends StatelessWidget {
  final ZeiterfassungLocal zeiterfassung;
  final DateFormat dateFormat;
  final String Function(int?) formatDauer;

  const _ZeiterfassungRow({
    required this.zeiterfassung,
    required this.dateFormat,
    required this.formatDauer,
  });

  @override
  Widget build(BuildContext context) {
    final zeitraum = (zeiterfassung.startZeit != null &&
            zeiterfassung.endZeit != null)
        ? '${zeiterfassung.startZeit} – ${zeiterfassung.endZeit}'
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateFormat.format(zeiterfassung.datum),
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14),
              ),
              if (zeitraum != null) ...[
                const SizedBox(width: 12),
                Text(
                  zeitraum,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
              const Spacer(),
              Text(
                '${formatDauer(zeiterfassung.dauerMinuten)} Std.',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ],
          ),
          if (zeiterfassung.beschreibung != null &&
              zeiterfassung.beschreibung!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                zeiterfassung.beschreibung!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}

class _RapportRow extends StatelessWidget {
  final RapportLocal rapport;
  final DateFormat dateFormat;
  final Color statusColor;
  final String statusLabel;

  const _RapportRow({
    required this.rapport,
    required this.dateFormat,
    required this.statusColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                dateFormat.format(rapport.datum),
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const Spacer(),
              _StatusBadge(
                label: statusLabel,
                color: statusColor,
              ),
            ],
          ),
          if (rapport.beschreibung != null &&
              rapport.beschreibung!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                rapport.beschreibung!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
