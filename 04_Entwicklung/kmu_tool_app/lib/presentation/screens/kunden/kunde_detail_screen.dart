import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/local/kunde_kontakt_local_export.dart';
import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';

class KundeDetailScreen extends ConsumerWidget {
  final String kundeId;

  const KundeDetailScreen({super.key, required this.kundeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kundeAsync = ref.watch(kundeProvider(kundeId));
    final kontakteAsync = ref.watch(kundeKontakteProvider(kundeId));
    final offertenAsync = ref.watch(offertenByKundeProvider(kundeId));
    final auftraegeAsync = ref.watch(auftraegeByKundeProvider(kundeId));

    return kundeAsync.when(
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
                Text('Fehler beim Laden: $error'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(kundeProvider(kundeId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (kunde) {
        if (kunde == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Kunde nicht gefunden')),
          );
        }

        final displayName = _displayName(kunde);

        return Scaffold(
          appBar: AppBar(
            title: Text(displayName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context.push('/kunden/$kundeId/bearbeiten');
                  ref.invalidate(kundeProvider(kundeId));
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Schnellaktionen ───
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      if (kunde.telefon != null &&
                          kunde.telefon!.isNotEmpty)
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.phone,
                            label: 'Anrufen',
                            color: AppColors.success,
                            onTap: () => _launchPhone(kunde.telefon!),
                          ),
                        ),
                      if (kunde.telefon != null &&
                          kunde.telefon!.isNotEmpty &&
                          kunde.email != null &&
                          kunde.email!.isNotEmpty)
                        const SizedBox(width: 12),
                      if (kunde.email != null && kunde.email!.isNotEmpty)
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.email_outlined,
                            label: 'E-Mail',
                            color: AppColors.primary,
                            onTap: () => _launchEmail(kunde.email!),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.description_outlined,
                          label: 'Neue Offerte',
                          color: AppColors.info,
                          onTap: () async {
                            await context
                                .push('/offerten/neu?kundeId=$kundeId');
                            ref.invalidate(
                                offertenByKundeProvider(kundeId));
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.assignment_outlined,
                          label: 'Neuer Auftrag',
                          color: AppColors.secondary,
                          onTap: () async {
                            await context.push('/auftraege/neu');
                            ref.invalidate(
                                auftraegeByKundeProvider(kundeId));
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ─── Kontaktdaten ───
                const _SectionHeader(title: 'Kontaktdaten'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (kunde.firma != null && kunde.firma!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.business,
                            label: 'Firma',
                            value: kunde.firma!,
                          ),
                        _DetailRow(
                          icon: Icons.person_outline,
                          label: 'Name',
                          value:
                              '${kunde.vorname ?? ''} ${kunde.nachname}'
                                  .trim(),
                        ),
                        if (kunde.telefon != null &&
                            kunde.telefon!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Telefon',
                            value: kunde.telefon!,
                          ),
                        if (kunde.email != null && kunde.email!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.email_outlined,
                            label: 'E-Mail',
                            value: kunde.email!,
                          ),
                      ],
                    ),
                  ),
                ),

                // ─── Adresse ───
                if (_hasAddress(kunde)) ...[
                  const _SectionHeader(title: 'Adresse'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (kunde.strasse != null &&
                              kunde.strasse!.isNotEmpty)
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'Strasse',
                              value: kunde.strasse!,
                            ),
                          if (kunde.plz != null || kunde.ort != null)
                            _DetailRow(
                              icon: Icons.map_outlined,
                              label: 'PLZ / Ort',
                              value:
                                  '${kunde.plz ?? ''} ${kunde.ort ?? ''}'
                                      .trim(),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ─── Notizen ───
                if (kunde.notizen != null &&
                    kunde.notizen!.isNotEmpty) ...[
                  const _SectionHeader(title: 'Notizen'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notes_outlined,
                              size: 20, color: AppColors.textSecondary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              kunde.notizen!,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // ─── Kontaktpersonen ───
                _SectionHeader(
                  title: 'Kontaktpersonen',
                  trailing: IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () async {
                      await context
                          .push('/kunden/$kundeId/kontakte/neu');
                      ref.invalidate(kundeKontakteProvider(kundeId));
                    },
                  ),
                ),
                kontakteAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (kontakte) {
                    if (kontakte.isEmpty) {
                      return const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Kontaktpersonen',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: kontakte
                          .map((k) => _KontaktCard(
                                kontakt: k,
                                onTap: () async {
                                  await context.push(
                                      '/kunden/$kundeId/kontakte/${k.routeId}/bearbeiten');
                                  ref.invalidate(
                                      kundeKontakteProvider(kundeId));
                                },
                              ))
                          .toList(),
                    );
                  },
                ),

                // ─── Verknuepfte Offerten ───
                const _SectionHeader(title: 'Verknuepfte Offerten'),
                offertenAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (offerten) {
                    if (offerten.isEmpty) {
                      return const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Offerten vorhanden',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: offerten
                          .map((o) => _OfferteCard(
                                offerte: o,
                                onTap: () =>
                                    context.push('/offerten/${o.routeId}'),
                              ))
                          .toList(),
                    );
                  },
                ),

                // ─── Verknuepfte Auftraege ───
                const _SectionHeader(title: 'Verknuepfte Auftraege'),
                auftraegeAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Fehler: $e'),
                  ),
                  data: (auftraege) {
                    if (auftraege.isEmpty) {
                      return const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Keine Auftraege vorhanden',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }
                    return Column(
                      children: auftraege
                          .map((a) => _AuftragCard(
                                auftrag: a,
                                onTap: () =>
                                    context.push('/auftraege/${a.routeId}'),
                              ))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _displayName(KundeLocal k) {
    if (k.firma != null && k.firma!.isNotEmpty) return k.firma!;
    return '${k.vorname ?? ''} ${k.nachname}'.trim();
  }

  bool _hasAddress(KundeLocal k) {
    return (k.strasse != null && k.strasse!.isNotEmpty) ||
        (k.plz != null && k.plz!.isNotEmpty) ||
        (k.ort != null && k.ort!.isNotEmpty);
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

// ─── Shared Widgets ───

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KontaktCard extends StatelessWidget {
  final KundeKontaktLocal kontakt;
  final VoidCallback onTap;

  const _KontaktCard({required this.kontakt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    AppColors.secondary.withValues(alpha: 0.1),
                child: const Icon(Icons.person_outline,
                    size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${kontakt.vorname} ${kontakt.nachname}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (kontakt.funktion != null &&
                        kontakt.funktion!.isNotEmpty)
                      Text(
                        kontakt.funktion!,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
              if (kontakt.telefon != null && kontakt.telefon!.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  onPressed: () async {
                    final uri =
                        Uri(scheme: 'tel', path: kontakt.telefon);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferteCard extends StatelessWidget {
  final OfferteLocal offerte;
  final VoidCallback onTap;

  const _OfferteCard({required this.offerte, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'entwurf':
        return AppColors.storniert;
      case 'gesendet':
        return AppColors.offen;
      case 'angenommen':
        return AppColors.abgeschlossen;
      case 'abgelehnt':
        return AppColors.error;
      default:
        return AppColors.storniert;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'entwurf':
        return 'Entwurf';
      case 'gesendet':
        return 'Gesendet';
      case 'angenommen':
        return 'Angenommen';
      case 'abgelehnt':
        return 'Abgelehnt';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.description_outlined,
            color: _statusColor(offerte.status)),
        title: Text(offerte.offertNr ?? 'Offerte'),
        subtitle: Text(
          'CHF ${offerte.totalBrutto.toStringAsFixed(2)}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: _StatusBadge(
          label: _statusLabel(offerte.status),
          color: _statusColor(offerte.status),
        ),
      ),
    );
  }
}

class _AuftragCard extends StatelessWidget {
  final AuftragLocal auftrag;
  final VoidCallback onTap;

  const _AuftragCard({required this.auftrag, required this.onTap});

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
        return 'Erledigt';
      case 'storniert':
        return 'Storniert';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(Icons.assignment_outlined,
            color: _statusColor(auftrag.status)),
        title: Text(auftrag.auftragsNr ?? 'Auftrag'),
        subtitle: auftrag.beschreibung != null
            ? Text(
                auftrag.beschreibung!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            : null,
        trailing: _StatusBadge(
          label: _statusLabel(auftrag.status),
          color: _statusColor(auftrag.status),
        ),
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
