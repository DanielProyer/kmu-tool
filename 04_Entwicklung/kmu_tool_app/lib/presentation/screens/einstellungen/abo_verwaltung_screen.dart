import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/subscription_plan.dart';
import 'package:kmu_tool_app/data/repositories/subscription_repository.dart';
import 'package:kmu_tool_app/presentation/providers/feature_provider.dart';
import 'package:kmu_tool_app/services/feature/feature_service.dart';

// ─── Providers ───

final _plansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  try {
    return await SubscriptionRepository.getPlans();
  } catch (_) {
    return []; // Tabelle existiert noch nicht
  }
});

// ─── Screen ───

class AboVerwaltungScreen extends ConsumerWidget {
  const AboVerwaltungScreen({super.key});

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  static const _featureLabels = {
    'kunden': 'Kundenverwaltung',
    'offerten': 'Offerten',
    'auftraege': 'Auftraege',
    'zeiterfassung': 'Zeiterfassung',
    'rapporte': 'Rapporte',
    'rechnungen': 'Rechnungen',
    'buchhaltung': 'Buchhaltung',
    'auftrag_dashboard': 'Auftrag-Dashboard',
    'auto_website': 'Auto-Website',
  };

  static const _featureIcons = {
    'kunden': Icons.people_outline,
    'offerten': Icons.description_outlined,
    'auftraege': Icons.assignment_outlined,
    'zeiterfassung': Icons.timer_outlined,
    'rapporte': Icons.note_alt_outlined,
    'rechnungen': Icons.receipt_long_outlined,
    'buchhaltung': Icons.account_balance_outlined,
    'auftrag_dashboard': Icons.dashboard_outlined,
    'auto_website': Icons.language,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPlanId = ref.watch(currentPlanIdProvider);
    final currentPlanName = ref.watch(currentPlanNameProvider);
    final plansAsync = ref.watch(_plansProvider);
    final theme = Theme.of(context);
    final sub = FeatureService.instance.currentSubscription;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/einstellungen'),
        ),
        title: const Text('Abo-Verwaltung'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Aktueller Plan ──
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.workspace_premium,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Aktueller Plan',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentPlanName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (sub != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: sub.isActive
                                ? AppStatusColors.success
                                    .withValues(alpha: 0.1)
                                : AppStatusColors.warning
                                    .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sub.isActive ? 'Aktiv' : sub.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sub.isActive
                                  ? AppStatusColors.success
                                  : AppStatusColors.warning,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (sub != null) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _InfoChip(
                          label: 'Gueltig ab',
                          value: DateFormat('dd.MM.yyyy', 'de_CH')
                              .format(sub.gueltigAb),
                        ),
                        const SizedBox(width: 16),
                        if (sub.gueltigBis != null)
                          _InfoChip(
                            label: 'Gueltig bis',
                            value: DateFormat('dd.MM.yyyy', 'de_CH')
                                .format(sub.gueltigBis!),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Verfuegbare Plaene ──
          Text(
            'Verfuegbare Plaene',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          plansAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (_, __) => _buildPlansUnavailable(context),
            data: (plans) {
              if (plans.isEmpty) {
                return _buildPlansUnavailable(context);
              }
              return Column(
                children: plans.map((plan) {
                  final isActive = plan.id == currentPlanId;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanCard(
                      plan: plan,
                      isActive: isActive,
                      formatCHF: _chf.format,
                      featureLabels: _featureLabels,
                      featureIcons: _featureIcons,
                      onSelect: isActive
                          ? null
                          : () => _switchPlan(context, ref, plan),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 16),

          // Hinweis
          Card(
            margin: EdgeInsets.zero,
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Planwechsel werden sofort wirksam. '
                      'Bei einem Downgrade behalten Sie den Zugang '
                      'bis zum Ende der aktuellen Abrechnungsperiode.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlansUnavailable(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.cloud_off,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Plaene konnten nicht geladen werden',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Momentan sind alle Features freigeschaltet.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchPlan(
    BuildContext context,
    WidgetRef ref,
    SubscriptionPlan plan,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Plan wechseln'),
        content: Text(
          'Moechten Sie zum Plan "${plan.bezeichnung}" '
          '(${_chf.format(plan.preisMonatlich)}/Mt.) wechseln?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Wechseln'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    try {
      await SubscriptionRepository.changePlan(plan.id);
      await FeatureService.instance.load();
      ref.invalidate(_plansProvider);
      ref.invalidate(currentPlanNameProvider);
      ref.invalidate(currentPlanIdProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan gewechselt zu "${plan.bezeichnung}"'),
            backgroundColor: AppStatusColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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
}

// ─── Helper Widgets ───

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isActive;
  final String Function(num) formatCHF;
  final Map<String, String> featureLabels;
  final Map<String, IconData> featureIcons;
  final VoidCallback? onSelect;

  const _PlanCard({
    required this.plan,
    required this.isActive,
    required this.formatCHF,
    required this.featureLabels,
    required this.featureIcons,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isActive ? 2 : 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color:
              isActive ? theme.colorScheme.primary : theme.dividerColor,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.bezeichnung,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isActive) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.preisMonatlich > 0
                            ? '${formatCHF(plan.preisMonatlich)} / Monat'
                            : 'Kostenlos',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 16),

            // Features
            ...featureLabels.entries.map((entry) {
              final featureKey = entry.key;
              final label = entry.value;
              final icon = featureIcons[featureKey] ?? Icons.check;
              final hasFeature = plan.hasFeature(featureKey);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(
                      hasFeature ? icon : Icons.remove,
                      size: 18,
                      color: hasFeature
                          ? AppStatusColors.success
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: hasFeature
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                        decoration: hasFeature
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Limits
            ..._buildLimits(context, plan),

            if (!isActive) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSelect,
                  child: Text('Zu ${plan.bezeichnung} wechseln'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLimits(BuildContext context, SubscriptionPlan plan) {
    final limits = <Widget>[];
    final theme = Theme.of(context);

    final maxKunden = plan.getLimit('max_kunden');
    final maxOfferten = plan.getLimit('max_offerten');

    if (maxKunden > 0 || maxOfferten > 0) {
      limits.add(const SizedBox(height: 8));
      limits.add(Divider(height: 1, color: theme.dividerColor));
      limits.add(const SizedBox(height: 8));
    }

    if (maxKunden > 0) {
      limits.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          'Max. $maxKunden Kunden',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ));
    }

    if (maxOfferten > 0) {
      limits.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          'Max. $maxOfferten Offerten',
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ));
    }

    return limits;
  }
}
