import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/presentation/providers/feature_provider.dart';
import 'package:kmu_tool_app/presentation/providers/theme_provider.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

class EinstellungenScreen extends ConsumerWidget {
  const EinstellungenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeConfigProvider);
    final planName = ref.watch(currentPlanNameProvider);
    final theme = Theme.of(context);
    final isGF = BetriebService.cachedRolle == 'geschaeftsfuehrer';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          // ─── Design ───
          const _SectionHeader(title: 'DESIGN'),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [themeConfig.primary, themeConfig.secondary],
                ),
              ),
            ),
            title: const Text('Farbdesign'),
            subtitle: Text(themeConfig.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/einstellungen/theme'),
          ),

          const Divider(height: 1),

          // ─── Abo ───
          const _SectionHeader(title: 'ABO'),
          ListTile(
            leading: Icon(
              Icons.workspace_premium,
              color: theme.colorScheme.primary,
            ),
            title: const Text('Aktueller Plan'),
            subtitle: Text(planName),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/einstellungen/abo'),
          ),

          // ─── Betrieb (nur GF) ───
          if (isGF) ...[
            const Divider(height: 1),
            const _SectionHeader(title: 'BETRIEB'),
            ListTile(
              leading: Icon(
                Icons.receipt_long_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('MWST-Einstellungen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/buchhaltung/mwst/einstellungen'),
            ),
            ListTile(
              leading: Icon(
                Icons.people_outline,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Mitarbeiter'),
              subtitle: const Text('Verwalten & einladen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/einstellungen/mitarbeiter'),
            ),
            ListTile(
              leading: Icon(
                Icons.directions_car_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Fahrzeuge'),
              subtitle: const Text('Fuhrpark verwalten'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/einstellungen/fahrzeuge'),
            ),
            ListTile(
              leading: Icon(
                Icons.fact_check_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: const Text('Inventur'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/inventur'),
            ),
          ],

          const Divider(height: 1),

          // ─── Info ───
          const _SectionHeader(title: 'INFO'),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            title: const Text('Version'),
            subtitle: const Text('1.0.0 (MVP)'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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
