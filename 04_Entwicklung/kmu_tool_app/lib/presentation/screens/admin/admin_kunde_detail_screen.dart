import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_kundenprofil_repository.dart';
import 'package:kmu_tool_app/services/admin/admin_service.dart';
import 'package:intl/intl.dart';

class AdminKundeDetailScreen extends ConsumerWidget {
  final String kundeProfilId;

  const AdminKundeDetailScreen({super.key, required this.kundeProfilId});

  Color _statusColor(String status) {
    switch (status) {
      case 'aktiv':
        return AppStatusColors.success;
      case 'inaktiv':
        return AppStatusColors.warning;
      case 'gesperrt':
        return AppStatusColors.error;
      case 'test':
        return AppStatusColors.info;
      default:
        return AppStatusColors.storniert;
    }
  }

  Color _rechnungStatusColor(String status) {
    switch (status) {
      case 'offen':
        return AppStatusColors.warning;
      case 'bezahlt':
        return AppStatusColors.success;
      case 'storniert':
        return AppStatusColors.storniert;
      case 'gemahnt':
        return AppStatusColors.error;
      default:
        return AppStatusColors.storniert;
    }
  }

  Color _migrationStatusColor(String status) {
    switch (status) {
      case 'geplant':
        return AppStatusColors.info;
      case 'in_bearbeitung':
        return AppStatusColors.warning;
      case 'abgeschlossen':
        return AppStatusColors.success;
      case 'fehler':
        return AppStatusColors.error;
      default:
        return AppStatusColors.storniert;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final profilAsync = ref.watch(adminKundeProvider(kundeProfilId));

    return profilAsync.when(
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
                      ref.invalidate(adminKundeProvider(kundeProfilId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (profil) {
        if (profil == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Kunde nicht gefunden')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.canPop(context)
                  ? context.pop()
                  : context.go('/admin/kunden'),
            ),
            title: Text(profil.firmaName),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context
                      .push('/admin/kunden/$kundeProfilId/bearbeiten');
                  ref.invalidate(adminKundeProvider(kundeProfilId));
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, ref, profil, value),
                itemBuilder: (context) => [
                  if (profil.status != 'aktiv')
                    const PopupMenuItem(
                      value: 'aktivieren',
                      child: ListTile(
                        leading: Icon(Icons.check_circle_outline,
                            color: AppStatusColors.success),
                        title: Text('Aktivieren'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  if (profil.status != 'inaktiv')
                    const PopupMenuItem(
                      value: 'deaktivieren',
                      child: ListTile(
                        leading: Icon(Icons.pause_circle_outline,
                            color: AppStatusColors.warning),
                        title: Text('Deaktivieren'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  if (profil.status != 'gesperrt')
                    const PopupMenuItem(
                      value: 'sperren',
                      child: ListTile(
                        leading: Icon(Icons.block,
                            color: AppStatusColors.error),
                        title: Text('Sperren'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'loeschen',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: AppStatusColors.error),
                      title: Text(
                        'Loeschen',
                        style:
                            TextStyle(color: AppStatusColors.error),
                      ),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminKundeProvider(kundeProfilId));
              if (profil.userId != null) {
                ref.invalidate(
                    adminKundeStatsProvider(profil.userId!));
              }
              ref.invalidate(
                  adminRechnungenByKundeProvider(kundeProfilId));
              ref.invalidate(
                  adminMigrationenByKundeProvider(kundeProfilId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── 1. Header Card ───
                  _HeaderCard(
                    profil: profil,
                    statusColor: _statusColor(profil.status),
                    colorScheme: colorScheme,
                  ),

                  // ─── 2. Kontaktdaten ───
                  const _SectionHeader(title: 'Kontaktdaten'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (profil.kontaktperson != null &&
                              profil.kontaktperson!.isNotEmpty)
                            _DetailRow(
                              icon: Icons.person_outline,
                              label: 'Kontakt',
                              value: profil.kontaktperson!,
                            ),
                          if (profil.email != null &&
                              profil.email!.isNotEmpty)
                            _DetailRow(
                              icon: Icons.email_outlined,
                              label: 'E-Mail',
                              value: profil.email!,
                            ),
                          if (profil.telefon != null &&
                              profil.telefon!.isNotEmpty)
                            _DetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Telefon',
                              value: profil.telefon!,
                            ),
                          if (profil.adresseEinzeilig.isNotEmpty)
                            _DetailRow(
                              icon: Icons.location_on_outlined,
                              label: 'Adresse',
                              value: profil.adresseEinzeilig,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ─── 3. Voreinstellungen ───
                  const _SectionHeader(title: 'Voreinstellungen'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: Icons.receipt_long_outlined,
                            label: 'MWST',
                            value: profil.mwstMethodeLabel,
                          ),
                          _DetailRow(
                            icon: Icons.people_outline,
                            label: 'Mitarbeiter',
                            value: '${profil.anzahlMitarbeiter}',
                          ),
                          _DetailRow(
                            icon: Icons.directions_car_outlined,
                            label: 'Fahrzeuge',
                            value: '${profil.anzahlFahrzeuge}',
                          ),
                          if (profil.branche != null &&
                              profil.branche!.isNotEmpty)
                            _DetailRow(
                              icon: Icons.work_outline,
                              label: 'Branche',
                              value: profil.branche!,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ─── 4. Nutzungs-Statistiken ───
                  if (profil.userId != null) ...[
                    const _SectionHeader(title: 'Nutzungs-Statistiken'),
                    _StatsSection(
                      userId: profil.userId!,
                      colorScheme: colorScheme,
                    ),
                  ],

                  // ─── 5. Plan & Features ───
                  const _SectionHeader(title: 'Plan & Features'),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.workspace_premium_outlined,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  profil.planBezeichnung ??
                                      'Kein Plan zugewiesen',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (profil.userId != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showPlanChangeDialog(
                                    context, ref, profil),
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('Plan wechseln'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // ─── 6. Rechnungen ───
                  const _SectionHeader(title: 'Rechnungen'),
                  _RechnungenSection(
                    kundeProfilId: kundeProfilId,
                    rechnungStatusColor: _rechnungStatusColor,
                    colorScheme: colorScheme,
                  ),

                  // ─── 7. Datenmigrationen ───
                  const _SectionHeader(title: 'Datenmigrationen'),
                  _MigrationenSection(
                    kundeProfilId: kundeProfilId,
                    migrationStatusColor: _migrationStatusColor,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref,
      dynamic profil, String action) async {
    switch (action) {
      case 'aktivieren':
        await _changeStatus(context, ref, 'aktiv');
        break;
      case 'deaktivieren':
        await _changeStatus(context, ref, 'inaktiv');
        break;
      case 'sperren':
        await _changeStatus(context, ref, 'gesperrt');
        break;
      case 'loeschen':
        await _confirmDelete(context, ref, profil);
        break;
    }
  }

  Future<void> _changeStatus(
      BuildContext context, WidgetRef ref, String newStatus) async {
    try {
      await AdminKundenprofilRepository.updateStatus(
          kundeProfilId, newStatus);
      ref.invalidate(adminKundeProvider(kundeProfilId));
      ref.invalidate(adminKundenListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status geaendert: $newStatus'),
            backgroundColor: AppStatusColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, dynamic profil) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kunde loeschen?'),
        content: Text(
          'Soll "${profil.firmaName}" wirklich geloescht werden? '
          'Diese Aktion kann nicht rueckgaengig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
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
        await AdminKundenprofilRepository.delete(kundeProfilId);
        ref.invalidate(adminKundenListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Kunde geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
          context.go('/admin/kunden');
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

  Future<void> _showPlanChangeDialog(
      BuildContext context, WidgetRef ref, dynamic profil) async {
    String? selectedPlanId = profil.planId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Plan wechseln'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aktueller Plan: ${profil.planBezeichnung ?? "Keiner"}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPlanId,
                decoration: const InputDecoration(
                  labelText: 'Neuer Plan',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'free', child: Text('Free')),
                  DropdownMenuItem(
                      value: 'standard', child: Text('Standard')),
                  DropdownMenuItem(
                      value: 'premium', child: Text('Premium')),
                ],
                onChanged: (value) {
                  setDialogState(() => selectedPlanId = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: selectedPlanId != null
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Speichern'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true &&
        selectedPlanId != null &&
        profil.userId != null &&
        context.mounted) {
      try {
        await AdminService.changeKundePlan(
            profil.userId!, selectedPlanId!);
        ref.invalidate(adminKundeProvider(kundeProfilId));
        ref.invalidate(adminKundenListProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Plan geaendert'),
              backgroundColor: AppStatusColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $e'),
              backgroundColor: AppStatusColors.error,
            ),
          );
        }
      }
    }
  }
}

// ─── Header Card ───

class _HeaderCard extends StatelessWidget {
  final dynamic profil;
  final Color statusColor;
  final ColorScheme colorScheme;

  const _HeaderCard({
    required this.profil,
    required this.statusColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    profil.firmaName.isNotEmpty
                        ? profil.firmaName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profil.firmaName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _Badge(
                            label: profil.statusLabel,
                            color: statusColor,
                          ),
                          const SizedBox(width: 8),
                          if (profil.planBezeichnung != null)
                            _Badge(
                              label: profil.planBezeichnung!,
                              color: colorScheme.secondary,
                              filled: false,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (profil.registriertAm != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 14, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Registriert am ${dateFormat.format(profil.registriertAm!)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Stats Section ───

class _StatsSection extends ConsumerWidget {
  final String userId;
  final ColorScheme colorScheme;

  const _StatsSection({
    required this.userId,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminKundeStatsProvider(userId));

    return statsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Fehler: $e'),
          ),
        ),
      ),
      data: (stats) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Kunden',
                    value: '${stats.kundenCount}',
                    icon: Icons.people_outline,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Offerten',
                    value: '${stats.offertenCount}',
                    icon: Icons.description_outlined,
                    colorScheme: colorScheme,
                    subtitle: '${stats.offeneOfferten} offen',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Auftraege',
                    value: '${stats.auftraegeCount}',
                    icon: Icons.assignment_outlined,
                    colorScheme: colorScheme,
                    subtitle: '${stats.aktiveAuftraege} aktiv',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Rechnungen',
                    value: '${stats.rechnungenCount}',
                    icon: Icons.receipt_outlined,
                    colorScheme: colorScheme,
                    subtitle:
                        'CHF ${stats.offeneRechnungenBetrag.toStringAsFixed(0)} offen',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Artikel',
                    value: '${stats.artikelCount}',
                    icon: Icons.inventory_2_outlined,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCard(
                    label: 'Buchungen',
                    value: '${stats.buchungenCount}',
                    icon: Icons.account_balance_outlined,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Card ───

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ColorScheme colorScheme;
  final String? subtitle;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colorScheme,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Rechnungen Section ───

class _RechnungenSection extends ConsumerWidget {
  final String kundeProfilId;
  final Color Function(String) rechnungStatusColor;
  final ColorScheme colorScheme;

  const _RechnungenSection({
    required this.kundeProfilId,
    required this.rechnungStatusColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rechnungenAsync =
        ref.watch(adminRechnungenByKundeProvider(kundeProfilId));
    final dateFormat = DateFormat('dd.MM.yyyy');

    return rechnungenAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Fehler: $e'),
          ),
        ),
      ),
      data: (rechnungen) {
        if (rechnungen.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Keine Rechnungen vorhanden',
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context
                          .push('/admin/rechnungen/neu?kundeId=$kundeProfilId'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Neue Rechnung'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final displayList = rechnungen.take(5).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ...displayList.map((r) => Card(
                    child: ListTile(
                      leading: Icon(Icons.receipt_outlined,
                          color: rechnungStatusColor(r.status)),
                      title: Text(r.rechnungsNr),
                      subtitle: Text(
                        r.createdAt != null
                            ? dateFormat.format(r.createdAt!)
                            : '',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CHF ${r.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _Badge(
                            label: r.statusLabel,
                            color: rechnungStatusColor(r.status),
                          ),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                          '/admin/rechnungen/neu?kundeId=$kundeProfilId'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Neue Rechnung'),
                    ),
                  ),
                  if (rechnungen.length > 5) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push(
                            '/admin/rechnungen?kundeId=$kundeProfilId'),
                        child: const Text('Alle Rechnungen'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Migrationen Section ───

class _MigrationenSection extends ConsumerWidget {
  final String kundeProfilId;
  final Color Function(String) migrationStatusColor;
  final ColorScheme colorScheme;

  const _MigrationenSection({
    required this.kundeProfilId,
    required this.migrationStatusColor,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final migrationenAsync =
        ref.watch(adminMigrationenByKundeProvider(kundeProfilId));
    final dateFormat = DateFormat('dd.MM.yyyy');

    return migrationenAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Fehler: $e'),
          ),
        ),
      ),
      data: (migrationen) {
        if (migrationen.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Keine Datenmigrationen vorhanden',
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push(
                          '/admin/migrationen/neu?kundeId=$kundeProfilId'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Neue Migration'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ...migrationen.map((m) => Card(
                    child: ListTile(
                      leading: Icon(Icons.sync_alt,
                          color: migrationStatusColor(m.status)),
                      title: Text(m.typLabel),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (m.createdAt != null)
                            Text(
                              dateFormat.format(m.createdAt!),
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (m.status == 'in_bearbeitung')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: LinearProgressIndicator(
                                value: m.fortschritt / 100,
                                backgroundColor: colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                        ],
                      ),
                      trailing: _Badge(
                        label: m.statusLabel,
                        color: migrationStatusColor(m.status),
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                      '/admin/migrationen/neu?kundeId=$kundeProfilId'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Neue Migration'),
                ),
              ),
            ],
          ),
        );
      },
    );
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
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
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

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool filled;

  const _Badge({
    required this.label,
    required this.color,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: filled ? null : Border.all(color: color.withValues(alpha: 0.5)),
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
