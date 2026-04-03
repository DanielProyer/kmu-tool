import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/admin/admin_dashboard_stats.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Admin-Panel'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardProvider);
          await ref.read(adminDashboardProvider.future);
        },
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _buildError(context, ref, error),
          data: (stats) => _buildContent(context, ref, stats),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
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
              onPressed: () => ref.invalidate(adminDashboardProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, AdminDashboardStats stats) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── 1. Kunden-Uebersicht ──
        Text(
          'Kunden-Uebersicht',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _MetricTile(
              label: 'Total Kunden',
              value: '${stats.totalKunden}',
              color: colorScheme.primary,
              icon: Icons.people,
            ),
            _MetricTile(
              label: 'Aktiv',
              value: '${stats.aktiveKunden}',
              color: AppStatusColors.success,
              icon: Icons.check_circle,
            ),
            _MetricTile(
              label: 'Inaktiv',
              value: '${stats.inaktiveKunden}',
              color: AppStatusColors.warning,
              icon: Icons.pause_circle,
            ),
            _MetricTile(
              label: 'Gesperrt',
              value: '${stats.gesperrteKunden}',
              color: AppStatusColors.error,
              icon: Icons.block,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── 2. Plan-Verteilung ──
        Text(
          'Plan-Verteilung',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PlanBadge(
                label: 'Free',
                count: stats.planFree,
                color: colorScheme.onSurfaceVariant,
                backgroundColor:
                    colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PlanBadge(
                label: 'Standard',
                count: stats.planStandard,
                color: colorScheme.primary,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PlanBadge(
                label: 'Premium',
                count: stats.planPremium,
                color: const Color(0xFFF59E0B),
                backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // ── 3. Rechnungen ──
        Text(
          'Rechnungen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.receipt_long,
                  iconColor: AppStatusColors.error,
                  label: 'Offene Rechnungen',
                  value:
                      '${stats.offeneRechnungenCount} / ${_formatCHF(stats.offeneRechnungenBetrag)}',
                  valueColor: AppStatusColors.error,
                ),
                const Divider(height: 20),
                _StatRow(
                  icon: Icons.warning_amber,
                  iconColor: AppStatusColors.warning,
                  label: 'Gemahnte',
                  value: '${stats.gemahnteRechnungenCount}',
                  valueColor: AppStatusColors.warning,
                ),
                const Divider(height: 20),
                _StatRow(
                  icon: Icons.trending_up,
                  iconColor: AppStatusColors.success,
                  label: 'Umsatz aktueller Monat',
                  value: _formatCHF(stats.bezahlteRechnungenMonat),
                  valueColor: AppStatusColors.success,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/admin/rechnungen'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Alle Rechnungen'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── 4. Datenmigrationen ──
        Text(
          'Datenmigrationen',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _StatRow(
                  icon: Icons.schedule,
                  iconColor: AppStatusColors.info,
                  label: 'Geplant',
                  value: '${stats.migrationenGeplant}',
                  valueColor: AppStatusColors.info,
                ),
                const Divider(height: 20),
                _StatRow(
                  icon: Icons.sync,
                  iconColor: AppStatusColors.warning,
                  label: 'In Bearbeitung',
                  value: '${stats.migrationenAktiv}',
                  valueColor: AppStatusColors.warning,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/admin/migrationen'),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text('Alle Migrationen'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── 5. Quick Actions ──
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.people,
                label: 'Alle Kunden',
                color: colorScheme.primary,
                onTap: () => context.push('/admin/kunden'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.receipt_long,
                label: 'Neue Rechnung',
                color: AppStatusColors.success,
                onTap: () => context.push('/admin/rechnungen/neu'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.import_export,
                label: 'Neue Migration',
                color: AppStatusColors.info,
                onTap: () => context.push('/admin/migrationen/neu'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
      ],
    );
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
}

// ─── Kunden-Uebersicht Tile ───

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Plan-Verteilung Badge ───

class _PlanBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color backgroundColor;

  const _PlanBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Stat Row inside Cards ───

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─── Quick Action Button ───

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
