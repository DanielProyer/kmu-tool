import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/admin/admin_rechnung.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_rechnung_repository.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';
import 'package:intl/intl.dart';

class AdminRechnungenScreen extends ConsumerStatefulWidget {
  const AdminRechnungenScreen({super.key});

  @override
  ConsumerState<AdminRechnungenScreen> createState() =>
      _AdminRechnungenScreenState();
}

class _AdminRechnungenScreenState
    extends ConsumerState<AdminRechnungenScreen> {
  String _filter = 'alle';

  final _dateFormat = DateFormat('dd.MM.yyyy', 'de_CH');

  static const _statusFilters = [
    'alle',
    'offen',
    'bezahlt',
    'gemahnt',
    'storniert',
  ];

  static const _statusLabels = {
    'alle': 'Alle',
    'offen': 'Offen',
    'bezahlt': 'Bezahlt',
    'gemahnt': 'Gemahnt',
    'storniert': 'Storniert',
  };

  Color _statusColor(String status) {
    switch (status) {
      case 'offen':
        return AppStatusColors.info;
      case 'bezahlt':
        return AppStatusColors.success;
      case 'gemahnt':
        return AppStatusColors.warning;
      case 'storniert':
        return AppStatusColors.storniert;
      default:
        return Colors.grey;
    }
  }

  /// Formats a double as Swiss CHF with apostrophe thousands separator.
  static String _formatCHF(double amount) {
    if (amount == 0) return 'CHF 0.00';
    final isNegative = amount < 0;
    final abs = amount.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write("'");
      }
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}CHF $buffer.$decPart';
  }

  Future<void> _markAsBezahlt(AdminRechnung rechnung) async {
    try {
      await AdminRechnungRepository.updateStatus(
        rechnung.id,
        'bezahlt',
        bezahltAm: DateTime.now(),
      );
      ref.invalidate(adminRechnungenListProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${rechnung.rechnungsNr} als bezahlt markiert'),
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
    }
  }

  Future<void> _markAsGemahnt(AdminRechnung rechnung) async {
    try {
      await AdminRechnungRepository.updateStatus(rechnung.id, 'gemahnt');
      ref.invalidate(adminRechnungenListProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${rechnung.rechnungsNr} als gemahnt markiert'),
            backgroundColor: AppStatusColors.warning,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final rechnungenAsync = ref.watch(adminRechnungenListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/admin'),
        ),
        title: const Text('Rechnungen (Admin)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
            onPressed: () => ref.invalidate(adminRechnungenListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/rechnungen/neu'),
        child: const Icon(Icons.add),
      ),
      body: rechnungenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, error),
        data: (rechnungen) => _buildContent(context, colorScheme, rechnungen),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: AppStatusColors.error),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(adminRechnungenListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    List<AdminRechnung> rechnungen,
  ) {
    // Client-side filtering
    final filtered = _filter == 'alle'
        ? rechnungen
        : rechnungen.where((r) => r.status == _filter).toList();

    // Summary calculations
    final offeneRechnungen =
        rechnungen.where((r) => r.status == 'offen').toList();
    final gemahnteRechnungen =
        rechnungen.where((r) => r.status == 'gemahnt').toList();
    final totalOffen =
        offeneRechnungen.fold<double>(0, (sum, r) => sum + r.total);
    final totalGemahnt =
        gemahnteRechnungen.fold<double>(0, (sum, r) => sum + r.total);

    final now = DateTime.now();
    final umsatzMonat = rechnungen
        .where((r) =>
            r.status == 'bezahlt' &&
            r.bezahltAm != null &&
            r.bezahltAm!.year == now.year &&
            r.bezahltAm!.month == now.month)
        .fold<double>(0, (sum, r) => sum + r.total);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminRechnungenListProvider);
        await ref.read(adminRechnungenListProvider.future);
      },
      child: Column(
        children: [
          // ── Summary Card ──
          Card(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryItem(
                      label: 'Offen',
                      value: _formatCHF(totalOffen),
                      color: AppStatusColors.info,
                      icon: Icons.receipt_long,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Gemahnt',
                      value: _formatCHF(totalGemahnt),
                      color: AppStatusColors.warning,
                      icon: Icons.warning_amber,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: _SummaryItem(
                      label: 'Umsatz Monat',
                      value: _formatCHF(umsatzMonat),
                      color: AppStatusColors.success,
                      icon: Icons.trending_up,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Filter Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _statusFilters.map((f) {
                final isSelected = f == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_statusLabels[f] ?? f),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── List ──
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64,
                            color: Theme.of(context).dividerColor),
                        const SizedBox(height: 16),
                        Text(
                          _filter == 'alle'
                              ? 'Noch keine Rechnungen'
                              : 'Keine Rechnungen mit Status "${_statusLabels[_filter]}"',
                          style: TextStyle(
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final rechnung = filtered[index];
                      return _RechnungCard(
                        rechnung: rechnung,
                        dateFormat: _dateFormat,
                        statusColor: _statusColor(rechnung.status),
                        onTap: () => context.push(
                            '/admin/rechnungen/${rechnung.id}'),
                        onMarkBezahlt:
                            (rechnung.status == 'offen' ||
                                    rechnung.status == 'gemahnt')
                                ? () => _markAsBezahlt(rechnung)
                                : null,
                        onMarkGemahnt: rechnung.status == 'offen'
                            ? () => _markAsGemahnt(rechnung)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Item ───

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── Rechnung Card ───

class _RechnungCard extends StatelessWidget {
  final AdminRechnung rechnung;
  final DateFormat dateFormat;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback? onMarkBezahlt;
  final VoidCallback? onMarkGemahnt;

  const _RechnungCard({
    required this.rechnung,
    required this.dateFormat,
    required this.statusColor,
    required this.onTap,
    this.onMarkBezahlt,
    this.onMarkGemahnt,
  });

  static String _formatCHF(double amount) {
    if (amount == 0) return 'CHF 0.00';
    final isNegative = amount < 0;
    final abs = amount.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write("'");
      }
      buffer.write(intPart[i]);
    }
    return '${isNegative ? '-' : ''}CHF $buffer.$decPart';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUeberfaellig = rechnung.status == 'offen' &&
        rechnung.faelligAm != null &&
        rechnung.faelligAm!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isUeberfaellig
              ? AppStatusColors.error.withValues(alpha: 0.5)
              : Theme.of(context).dividerColor,
          width: isUeberfaellig ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Rechnungs-Nr + Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      rechnung.rechnungsNr,
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _StatusBadge(
                    label: rechnung.statusLabel,
                    color: statusColor,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Kunde
              Row(
                children: [
                  Icon(Icons.business_outlined,
                      size: 16, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      rechnung.kundeFirma ?? 'Unbekannter Kunde',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Bottom row: Fällig am + Total
              Row(
                children: [
                  if (rechnung.faelligAm != null) ...[
                    Icon(
                      Icons.event_outlined,
                      size: 14,
                      color: isUeberfaellig
                          ? AppStatusColors.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Fällig: ${dateFormat.format(rechnung.faelligAm!)}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: isUeberfaellig
                                ? AppStatusColors.error
                                : colorScheme.onSurfaceVariant,
                            fontWeight:
                                isUeberfaellig ? FontWeight.w600 : null,
                          ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatCHF(rechnung.total),
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),

              // Ueberfaellig warning
              if (isUeberfaellig) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppStatusColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppStatusColors.error),
                      const SizedBox(width: 4),
                      Text(
                        'Ueberfaellig',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: AppStatusColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],

              // Quick actions
              if (onMarkBezahlt != null || onMarkGemahnt != null) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onMarkGemahnt != null)
                      TextButton.icon(
                        onPressed: onMarkGemahnt,
                        icon: const Icon(Icons.warning_amber, size: 16),
                        label: const Text('Mahnen'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppStatusColors.warning,
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    if (onMarkBezahlt != null) ...[
                      if (onMarkGemahnt != null) const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onMarkBezahlt,
                        icon: const Icon(Icons.check_circle_outline,
                            size: 16),
                        label: const Text('Bezahlt'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppStatusColors.success,
                          visualDensity: VisualDensity.compact,
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Status Badge ───

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
