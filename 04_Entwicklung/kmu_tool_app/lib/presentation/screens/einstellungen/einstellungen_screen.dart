import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/presentation/providers/feature_provider.dart';
import 'package:kmu_tool_app/presentation/providers/theme_provider.dart';

class EinstellungenScreen extends ConsumerWidget {
  const EinstellungenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfig = ref.watch(themeConfigProvider);
    final planName = ref.watch(currentPlanNameProvider);
    final theme = Theme.of(context);

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
            onTap: () {
              // TODO: Abo-Verwaltung Screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Abo-Verwaltung kommt bald'),
                ),
              );
            },
          ),

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
