import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/config/features.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/presentation/providers/dashboard_provider.dart';
import 'package:kmu_tool_app/presentation/providers/feature_provider.dart';
import 'package:kmu_tool_app/services/connectivity/connectivity_service.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/services/sync/sync_service_export.dart';
import 'package:kmu_tool_app/services/admin/admin_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  SyncState _syncState = SyncState.idle;
  bool _isOnline = ConnectivityService.isOnline;
  late final StreamSubscription<SyncState> _syncSub;
  late final StreamSubscription<bool> _connectSub;

  @override
  void initState() {
    super.initState();
    _syncState = SyncService.state;
    _syncSub = SyncService.stateStream.listen((state) {
      if (mounted) setState(() => _syncState = state);
    });
    _connectSub = ConnectivityService.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _syncSub.cancel();
    _connectSub.cancel();
    super.dispose();
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abmelden'),
        content: const Text('Möchtest du dich wirklich abmelden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await SupabaseService.client.auth.signOut();
    }
  }

  Widget _buildSyncIndicator() {
    IconData icon;
    Color color;
    String tooltip;

    if (!_isOnline) {
      icon = Icons.cloud_off;
      color = AppStatusColors.offline;
      tooltip = 'Offline';
    } else {
      switch (_syncState) {
        case SyncState.syncing:
          return Tooltip(
            message: 'Synchronisiere...',
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppStatusColors.syncing,
              ),
            ),
          );
        case SyncState.error:
          icon = Icons.sync_problem;
          color = AppStatusColors.warning;
          tooltip = 'Sync-Fehler';
        case SyncState.idle:
          icon = Icons.cloud_done;
          color = AppStatusColors.online;
          tooltip = 'Synchronisiert';
      }
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 22),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KMU Tool'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _buildSyncIndicator(),
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Jetzt synchronisieren',
            onPressed: () {
              SyncService.syncAll();
              ref.invalidate(dashboardProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => context.push('/einstellungen'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Abmelden',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          await ref.read(dashboardProvider.future);
        },
        child: dashboardAsync.when(
          data: (data) => _buildDashboard(context, data),
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => _buildErrorState(context, error),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppStatusColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(dashboardProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardData data) {
    final hasKunden = ref.watch(hasFeatureProvider(AppFeature.kunden));
    final hasOfferten = ref.watch(hasFeatureProvider(AppFeature.offerten));
    final hasAuftraege = ref.watch(hasFeatureProvider(AppFeature.auftraege));
    final hasRechnungen = ref.watch(hasFeatureProvider(AppFeature.rechnungen));
    final hasBuchhaltung = ref.watch(hasFeatureProvider(AppFeature.buchhaltung));
    final hasArtikel = ref.watch(hasFeatureProvider(AppFeature.artikel));
    final hasBestellwesen = ref.watch(hasFeatureProvider(AppFeature.bestellwesen));
    final hasInventur = ref.watch(hasFeatureProvider(AppFeature.inventur));

    final colorScheme = Theme.of(context).colorScheme;
    final allTiles = <_DashboardTileData>[
      if (hasKunden)
        _DashboardTileData(
          label: 'Kunden',
          icon: Icons.people,
          value: '${data.kundenCount}',
          color: colorScheme.primary,
          route: '/kunden',
        ),
      if (hasOfferten)
        _DashboardTileData(
          label: 'Offene Offerten',
          icon: Icons.description,
          value: '${data.offeneOffertenCount}',
          color: colorScheme.secondary,
          route: '/offerten',
        ),
      if (hasAuftraege)
        _DashboardTileData(
          label: 'Aktive Auftraege',
          icon: Icons.work,
          value: '${data.aktiveAuftraegeCount}',
          color: AppStatusColors.inBearbeitung,
          route: '/auftraege',
        ),
      if (hasRechnungen)
        _DashboardTileData(
          label: 'Offene Rechnungen',
          icon: Icons.receipt_long,
          value: _formatCHF(data.offeneRechnungenBetrag),
          color: AppStatusColors.error,
          route: '/rechnungen',
        ),
      if (hasBuchhaltung)
        _DashboardTileData(
          label: 'Buchhaltung',
          icon: Icons.account_balance,
          value: '',
          color: const Color(0xFF7C3AED),
          route: '/buchhaltung',
        ),
      if (hasArtikel)
        _DashboardTileData(
          label: 'Artikelstamm',
          icon: Icons.inventory_2,
          value: '${data.artikelCount}',
          color: const Color(0xFF0D9488),
          route: '/artikel',
        ),
      if (hasBestellwesen)
        _DashboardTileData(
          label: 'Bestellungen',
          icon: Icons.shopping_cart,
          value: '',
          color: const Color(0xFFD97706),
          route: '/bestellungen',
        ),
      if (hasInventur)
        _DashboardTileData(
          label: 'Inventur',
          icon: Icons.fact_check,
          value: '',
          color: const Color(0xFF6366F1),
          route: '/inventur',
        ),
      if (AdminService.isAdmin)
        _DashboardTileData(
          label: 'Admin-Panel',
          icon: Icons.admin_panel_settings,
          value: '',
          color: const Color(0xFFDC2626),
          route: '/admin',
        ),
      _DashboardTileData(
        label: 'Sync Status',
        icon: _isOnline ? Icons.cloud_done : Icons.cloud_off,
        value: _isOnline ? 'Online' : 'Offline',
        color: _isOnline ? AppStatusColors.online : AppStatusColors.offline,
        route: null,
      ),
    ];
    final tiles = allTiles;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Greeting
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _formattedDate(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),

        // Dashboard Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
            final childAspectRatio =
                constraints.maxWidth > 600 ? 1.4 : 1.15;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                return _DashboardTile(data: tiles[index]);
              },
            );
          },
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Guten Morgen';
    if (hour < 17) return 'Guten Nachmittag';
    return 'Guten Abend';
  }

  String _formattedDate() {
    final now = DateTime.now();
    const weekdays = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    const months = [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day}. ${months[now.month - 1]} ${now.year}';
  }

  String _formatCHF(double amount) {
    if (amount == 0) return 'CHF 0.00';
    // Format with thousands separator and 2 decimals
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    // Add apostrophe as Swiss thousands separator
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write("'");
      }
      buffer.write(intPart[i]);
    }
    return 'CHF $buffer.$decPart';
  }
}

class _DashboardTileData {
  final String label;
  final IconData icon;
  final String value;
  final Color color;
  final String? route;

  _DashboardTileData({
    required this.label,
    required this.icon,
    required this.value,
    required this.color,
    required this.route,
  });
}

class _DashboardTile extends StatelessWidget {
  final _DashboardTileData data;

  const _DashboardTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: data.route != null ? () => context.go(data.route!) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon Container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 24,
                ),
              ),
              const Spacer(),

              // Value
              if (data.value.isNotEmpty)
                Text(
                  data.value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: data.value.length > 10 ? 16 : 22,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 4),

              // Label
              Text(
                data.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
