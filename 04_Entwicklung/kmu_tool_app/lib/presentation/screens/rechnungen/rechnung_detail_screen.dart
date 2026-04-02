import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/rechnung.dart';
import 'package:kmu_tool_app/data/models/rechnungs_position.dart';
import 'package:kmu_tool_app/data/models/kunde.dart';
import 'package:kmu_tool_app/data/repositories/rechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/rechnungs_position_repository.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/data/repositories/user_profile_repository.dart';
import 'package:kmu_tool_app/data/models/user_profile.dart';
import 'package:kmu_tool_app/services/pdf/rechnung_pdf_service.dart';
import 'package:kmu_tool_app/services/rechnung/buchung_service.dart';

// ─── Providers ───

final _rechnungProvider =
    FutureProvider.family<Rechnung?, String>((ref, id) async {
  final repo = RechnungRepository();
  return repo.getById(id);
});

final _rechnungsPositionenProvider =
    FutureProvider.family<List<RechnungsPosition>, String>((ref, id) async {
  final repo = RechnungsPositionRepository();
  return repo.getByRechnung(id);
});

final _kundeForRechnungProvider =
    FutureProvider.family<Kunde?, String>((ref, kundeId) async {
  final kl = await KundeRepository.getAll();
  final match = kl.where((k) =>
      (k.serverId ?? k.id.toString()) == kundeId);
  if (match.isEmpty) return null;
  final k = match.first;
  return Kunde(
    id: k.serverId ?? k.id.toString(),
    userId: k.userId,
    firma: k.firma,
    vorname: k.vorname,
    nachname: k.nachname,
    strasse: k.strasse,
    plz: k.plz,
    ort: k.ort,
    telefon: k.telefon,
    email: k.email,
  );
});

final _userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repo = UserProfileRepository();
  return repo.get();
});

class RechnungDetailScreen extends ConsumerStatefulWidget {
  final String rechnungId;

  const RechnungDetailScreen({super.key, required this.rechnungId});

  @override
  ConsumerState<RechnungDetailScreen> createState() =>
      _RechnungDetailScreenState();
}

class _RechnungDetailScreenState extends ConsumerState<RechnungDetailScreen> {
  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'de_CH', symbol: 'CHF');
  bool _isUpdating = false;

  Color _statusColor(String status) {
    switch (status) {
      case 'entwurf':
        return Colors.grey;
      case 'gesendet':
        return AppStatusColors.info;
      case 'bezahlt':
        return AppStatusColors.success;
      case 'storniert':
        return Colors.grey;
      case 'gemahnt':
        return AppStatusColors.error;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'entwurf':
        return 'Entwurf';
      case 'gesendet':
        return 'Gesendet';
      case 'bezahlt':
        return 'Bezahlt';
      case 'storniert':
        return 'Storniert';
      case 'gemahnt':
        return 'Gemahnt';
      default:
        return status;
    }
  }

  Future<void> _markAsBezahlt(Rechnung rechnung) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Als bezahlt markieren?'),
        content: Text(
          'Rechnung ${rechnung.rechnungsNr} als bezahlt markieren?\n'
          'Es wird automatisch eine Buchung erstellt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bezahlt'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUpdating = true);
    try {
      final buchungService = BuchungService();
      await buchungService.markAsBezahlt(rechnung.id);
      ref.invalidate(_rechnungProvider(widget.rechnungId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Rechnung als bezahlt markiert'),
            backgroundColor: AppStatusColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppStatusColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _changeStatus(Rechnung rechnung) async {
    final statuses = ['entwurf', 'gesendet', 'bezahlt', 'gemahnt', 'storniert'];
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Status ändern'),
        children: statuses.map((s) {
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(context, s),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _statusColor(s),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _statusLabel(s),
                  style: TextStyle(
                    fontWeight:
                        s == rechnung.status ? FontWeight.bold : null,
                  ),
                ),
                if (s == rechnung.status) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, size: 16),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );

    if (selected == null || selected == rechnung.status) return;

    setState(() => _isUpdating = true);
    try {
      final repo = RechnungRepository();
      await repo.updateStatus(rechnung.id, selected);
      ref.invalidate(_rechnungProvider(widget.rechnungId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status auf "${_statusLabel(selected)}" geändert'),
            backgroundColor: AppStatusColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: AppStatusColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _generatePdf(
    Rechnung rechnung,
    List<RechnungsPosition> positionen,
    Kunde? kunde,
    UserProfile? profile,
  ) async {
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Benutzerprofil nicht geladen'),
          backgroundColor: AppStatusColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (kunde == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kundendaten nicht geladen'),
          backgroundColor: AppStatusColors.warning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    try {
      await RechnungPdfService.generateAndPreview(
        rechnung: rechnung,
        positionen: positionen,
        kunde: kunde,
        profile: profile,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF-Fehler: $e'),
            backgroundColor: AppStatusColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rechnungAsync = ref.watch(_rechnungProvider(widget.rechnungId));
    final positionenAsync =
        ref.watch(_rechnungsPositionenProvider(widget.rechnungId));
    final profileAsync = ref.watch(_userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/rechnungen'),
        ),
        title: rechnungAsync.whenOrNull(
              data: (r) => Text(r?.rechnungsNr ?? 'Rechnung'),
            ) ??
            const Text('Rechnung'),
        actions: [
          // PDF button
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF erstellen',
            onPressed: () {
              final rechnung = rechnungAsync.valueOrNull;
              final positionen = positionenAsync.valueOrNull ?? [];
              final profile = profileAsync.valueOrNull;
              if (rechnung == null) return;
              final kundeAsync =
                  ref.read(_kundeForRechnungProvider(rechnung.kundeId));
              final kunde = kundeAsync.valueOrNull;
              _generatePdf(rechnung, positionen, kunde, profile);
            },
          ),
        ],
      ),
      body: rechnungAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Fehler: $e',
              style: TextStyle(color: AppStatusColors.error)),
        ),
        data: (rechnung) {
          if (rechnung == null) {
            return const Center(child: Text('Rechnung nicht gefunden'));
          }

          final kundeAsync =
              ref.watch(_kundeForRechnungProvider(rechnung.kundeId));
          final kunde = kundeAsync.valueOrNull;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header Card ───
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status + Nr
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              rechnung.rechnungsNr,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            _StatusBadge(
                              label: _statusLabel(rechnung.status),
                              color: _statusColor(rechnung.status),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Kunde
                        _InfoRow(
                          icon: Icons.person_outlined,
                          label: 'Kunde',
                          value: kunde?.displayName ?? 'Laden...',
                        ),
                        if (kunde?.vollstaendigeAdresse.isNotEmpty == true)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'Adresse',
                            value: kunde!.vollstaendigeAdresse,
                          ),
                        const SizedBox(height: 8),

                        // Datum
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Datum',
                          value: _dateFormat.format(rechnung.datum),
                        ),
                        _InfoRow(
                          icon: Icons.event_outlined,
                          label: 'Fällig am',
                          value: _dateFormat.format(rechnung.faelligAm),
                          valueColor: rechnung.status == 'gesendet' &&
                                  rechnung.faelligAm.isBefore(DateTime.now())
                              ? AppStatusColors.error
                              : null,
                        ),

                        // QR-Referenz
                        if (rechnung.qrReferenz != null &&
                            rechnung.qrReferenz!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.qr_code_outlined,
                            label: 'QR-Referenz',
                            value: rechnung.qrReferenz!,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Positionen ───
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Positionen',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        positionenAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator()),
                          error: (e, _) =>
                              Text('Fehler: $e'),
                          data: (positionen) {
                            if (positionen.isEmpty) {
                              return Text(
                                'Keine Positionen vorhanden',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                              );
                            }
                            return Column(
                              children: [
                                // Table header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: Theme.of(context).dividerColor),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(
                                          width: 30,
                                          child: Text('Nr',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12))),
                                      const Expanded(
                                          flex: 3,
                                          child: Text('Bezeichnung',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12))),
                                      const SizedBox(
                                          width: 50,
                                          child: Text('Menge',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12))),
                                      const SizedBox(
                                          width: 70,
                                          child: Text('Preis',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12))),
                                      const SizedBox(
                                          width: 80,
                                          child: Text('Betrag',
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize: 12))),
                                    ],
                                  ),
                                ),
                                // Table rows
                                ...positionen.map((p) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 4),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                              color: Theme.of(context).dividerColor,
                                              width: 0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                              width: 30,
                                              child: Text(
                                                  '${p.positionNr}',
                                                  style: const TextStyle(
                                                      fontSize: 13))),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(p.bezeichnung,
                                                    style:
                                                        const TextStyle(
                                                            fontSize:
                                                                13)),
                                                Text(p.einheit,
                                                    style:
                                                        TextStyle(
                                                            fontSize: 11,
                                                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                              width: 50,
                                              child: Text(
                                                  p.menge
                                                      .toStringAsFixed(
                                                          p.menge ==
                                                                  p.menge
                                                                      .roundToDouble()
                                                              ? 0
                                                              : 2),
                                                  textAlign:
                                                      TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13))),
                                          SizedBox(
                                              width: 70,
                                              child: Text(
                                                  p.einheitspreis
                                                      .toStringAsFixed(
                                                          2),
                                                  textAlign:
                                                      TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13))),
                                          SizedBox(
                                              width: 80,
                                              child: Text(
                                                  p.betrag
                                                      .toStringAsFixed(
                                                          2),
                                                  textAlign:
                                                      TextAlign.right,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight
                                                              .w500))),
                                        ],
                                      ),
                                    )),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // ─── Totals ───
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _TotalRow(
                                label: 'Netto',
                                value: _currencyFormat
                                    .format(rechnung.totalNetto),
                              ),
                              const SizedBox(height: 4),
                              _TotalRow(
                                label:
                                    'MWST (${rechnung.mwstSatz.toStringAsFixed(1)}%)',
                                value: _currencyFormat
                                    .format(rechnung.mwstBetrag),
                              ),
                              const Divider(height: 16),
                              _TotalRow(
                                label: 'Brutto',
                                value: _currencyFormat
                                    .format(rechnung.totalBrutto),
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Action Buttons ───
                if (_isUpdating)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  // PDF erstellen
                  FilledButton.icon(
                    onPressed: () {
                      final positionen =
                          positionenAsync.valueOrNull ?? [];
                      final profile = profileAsync.valueOrNull;
                      _generatePdf(
                          rechnung, positionen, kunde, profile);
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('PDF erstellen'),
                  ),
                  const SizedBox(height: 12),

                  // Als bezahlt markieren
                  if (rechnung.status == 'gesendet' ||
                      rechnung.status == 'gemahnt')
                    OutlinedButton.icon(
                      onPressed: () => _markAsBezahlt(rechnung),
                      icon: Icon(Icons.check_circle_outlined,
                          color: AppStatusColors.success),
                      label: const Text('Als bezahlt markieren'),
                    ),
                  const SizedBox(height: 12),

                  // Status ändern
                  OutlinedButton.icon(
                    onPressed: () => _changeStatus(rechnung),
                    icon: const Icon(Icons.sync_alt_outlined),
                    label: const Text('Status ändern'),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
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
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: valueColor,
                    fontWeight: valueColor != null ? FontWeight.w600 : null,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _TotalRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            fontSize: isBold ? 15 : 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            fontSize: isBold ? 15 : 13,
          ),
        ),
      ],
    );
  }
}
