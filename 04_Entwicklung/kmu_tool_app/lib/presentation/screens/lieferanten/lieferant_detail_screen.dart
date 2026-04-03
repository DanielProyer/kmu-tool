import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/lieferant.dart';
import 'package:kmu_tool_app/data/repositories/lieferant_repository.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class LieferantDetailScreen extends ConsumerWidget {
  final String lieferantId;

  const LieferantDetailScreen({super.key, required this.lieferantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final lieferantAsync = ref.watch(lieferantProvider(lieferantId));

    return lieferantAsync.when(
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
                      ref.invalidate(lieferantProvider(lieferantId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (lieferant) {
        if (lieferant == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Lieferant nicht gefunden')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.canPop(context)
                  ? context.pop()
                  : context.go('/lieferanten'),
            ),
            title: Text(lieferant.firma),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  await context
                      .push('/lieferanten/$lieferantId/bearbeiten');
                  ref.invalidate(lieferantProvider(lieferantId));
                  ref.invalidate(lieferantenListProvider);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    await _confirmDelete(context, ref, lieferant);
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
                // ─── Schnellaktionen ───
                if (_hasQuickActions(lieferant))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        if (lieferant.telefon != null &&
                            lieferant.telefon!.isNotEmpty)
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.phone,
                              label: 'Anrufen',
                              color: AppStatusColors.success,
                              onTap: () =>
                                  _launchPhone(context, lieferant.telefon!),
                            ),
                          ),
                        if (lieferant.telefon != null &&
                            lieferant.telefon!.isNotEmpty &&
                            lieferant.email != null &&
                            lieferant.email!.isNotEmpty)
                          const SizedBox(width: 12),
                        if (lieferant.email != null &&
                            lieferant.email!.isNotEmpty)
                          Expanded(
                            child: _ActionButton(
                              icon: Icons.email_outlined,
                              label: 'E-Mail',
                              color: colorScheme.primary,
                              onTap: () =>
                                  _launchEmail(context, lieferant.email!),
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
                        _DetailRow(
                          icon: Icons.business,
                          label: 'Firma',
                          value: lieferant.firma,
                        ),
                        if (lieferant.kontaktperson != null &&
                            lieferant.kontaktperson!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Kontakt',
                            value: lieferant.kontaktperson!,
                          ),
                        if (lieferant.strasse != null &&
                            lieferant.strasse!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.location_on_outlined,
                            label: 'Strasse',
                            value: lieferant.strasse!,
                          ),
                        if (lieferant.plz != null || lieferant.ort != null)
                          _DetailRow(
                            icon: Icons.map_outlined,
                            label: 'PLZ / Ort',
                            value:
                                '${lieferant.plz ?? ''} ${lieferant.ort ?? ''}'
                                    .trim(),
                          ),
                        if (lieferant.telefon != null &&
                            lieferant.telefon!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Telefon',
                            value: lieferant.telefon!,
                          ),
                        if (lieferant.email != null &&
                            lieferant.email!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.email_outlined,
                            label: 'E-Mail',
                            value: lieferant.email!,
                          ),
                        if (lieferant.website != null &&
                            lieferant.website!.isNotEmpty)
                          _DetailRow(
                            icon: Icons.language,
                            label: 'Website',
                            value: lieferant.website!,
                          ),
                      ],
                    ),
                  ),
                ),

                // ─── Konditionen ───
                const _SectionHeader(title: 'Konditionen'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.schedule_outlined,
                          label: 'Zahlungsfrist',
                          value: '${lieferant.zahlungsfristTage} Tage',
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Notizen ───
                if (lieferant.notizen != null &&
                    lieferant.notizen!.isNotEmpty) ...[
                  const _SectionHeader(title: 'Notizen'),
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
                              lieferant.notizen!,
                              style: const TextStyle(fontSize: 14),
                            ),
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

  bool _hasQuickActions(Lieferant lieferant) {
    return (lieferant.telefon != null && lieferant.telefon!.isNotEmpty) ||
        (lieferant.email != null && lieferant.email!.isNotEmpty);
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    try {
      await launchUrl(Uri.parse('tel:$phone'));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anruf konnte nicht gestartet werden: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    try {
      await launchUrl(Uri.parse('mailto:$email'));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('E-Mail konnte nicht geoeffnet werden: $e'),
            backgroundColor: AppStatusColors.error,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Lieferant lieferant,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lieferant loeschen?'),
        content: Text(
          'Moechtest du "${lieferant.firma}" wirklich loeschen? '
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
        await LieferantRepository.delete(lieferant.id);
        if (context.mounted) {
          ref.invalidate(lieferantenListProvider);
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${lieferant.firma}" geloescht'),
              backgroundColor: AppStatusColors.success,
            ),
          );
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
}

// ─── Shared Widgets ───

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
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

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
