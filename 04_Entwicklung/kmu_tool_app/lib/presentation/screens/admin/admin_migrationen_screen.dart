import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/admin/admin_datenmigration.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_datenmigration_repository.dart';
import 'package:kmu_tool_app/presentation/providers/admin_providers.dart';
import 'package:intl/intl.dart';

class AdminMigrationenScreen extends ConsumerStatefulWidget {
  const AdminMigrationenScreen({super.key});

  @override
  ConsumerState<AdminMigrationenScreen> createState() =>
      _AdminMigrationenScreenState();
}

class _AdminMigrationenScreenState
    extends ConsumerState<AdminMigrationenScreen> {
  String _selectedFilter = 'alle';

  static const _filterOptions = [
    ('alle', 'Alle'),
    ('geplant', 'Geplant'),
    ('in_bearbeitung', 'In Bearbeitung'),
    ('abgeschlossen', 'Abgeschlossen'),
    ('fehler', 'Fehler'),
  ];

  List<AdminDatenmigration> _filterMigrationen(
      List<AdminDatenmigration> migrationen) {
    if (_selectedFilter == 'alle') return migrationen;
    return migrationen.where((m) => m.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final migrationenAsync = ref.watch(adminMigrationenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/admin'),
        ),
        title: const Text('Datenmigrationen'),
      ),
      body: Column(
        children: [
          // ── Filter Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filterOptions.map((option) {
                final (value, label) = option;
                final isSelected = _selectedFilter == value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = value);
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.onPrimaryContainer,
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Content ──
          Expanded(
            child: migrationenAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(context, ref, error),
              data: (migrationen) {
                final filtered = _filterMigrationen(migrationen);

                if (migrationen.isEmpty) {
                  return _buildEmpty(colorScheme);
                }

                if (filtered.isEmpty) {
                  return _buildNoResults(colorScheme);
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminMigrationenListProvider);
                    await ref.read(adminMigrationenListProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 4, bottom: 88),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _MigrationCard(
                        migration: filtered[index],
                        onStatusChanged: (id, newStatus, fortschritt) async {
                          await _updateStatus(id, newStatus, fortschritt);
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/admin/migrationen/neu');
          ref.invalidate(adminMigrationenListProvider);
        },
        child: const Icon(Icons.add),
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
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref.invalidate(adminMigrationenListProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.import_export_outlined,
              size: 72,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Noch keine Migrationen erfasst',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle eine neue Datenmigration mit dem + Button',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults(ColorScheme colorScheme) {
    final filterLabel = _filterOptions
        .firstWhere((o) => o.$1 == _selectedFilter,
            orElse: () => ('', _selectedFilter))
        .$2;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Migrationen mit Status "$filterLabel"',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(
      String id, String newStatus, int fortschritt) async {
    try {
      await AdminDatenmigrationRepository.updateStatus(
        id,
        newStatus,
        fortschritt: fortschritt,
      );
      ref.invalidate(adminMigrationenListProvider);
      ref.invalidate(adminDashboardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status aktualisiert'),
            backgroundColor: AppStatusColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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

// ─── Migration Card ───

class _MigrationCard extends StatelessWidget {
  final AdminDatenmigration migration;
  final Future<void> Function(String id, String newStatus, int fortschritt)
      onStatusChanged;

  const _MigrationCard({
    required this.migration,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header: Icon + Title + Status Badge ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Leading icon based on typ
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _typColor(migration.typ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _typIcon(migration.typ),
                    color: _typColor(migration.typ),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${migration.kundeFirma ?? 'Unbekannt'} - ${migration.typLabel}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (migration.module.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          migration.module.join(', '),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (migration.quellBeschreibung != null &&
                          migration.quellBeschreibung!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          migration.quellBeschreibung!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Status badge
                _StatusBadge(status: migration.status, label: migration.statusLabel),
              ],
            ),

            // ── Progress bar if in_bearbeitung ──
            if (migration.status == 'in_bearbeitung') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: migration.fortschritt / 100.0,
                        minHeight: 8,
                        backgroundColor:
                            colorScheme.onSurface.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppStatusColors.warning),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${migration.fortschritt}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppStatusColors.warning,
                    ),
                  ),
                ],
              ),
            ],

            // ── Footer: Date + Quick Actions ──
            const SizedBox(height: 12),
            Row(
              children: [
                if (migration.createdAt != null)
                  Text(
                    dateFormat.format(migration.createdAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                const Spacer(),
                // Quick action: status transition
                if (migration.status != 'abgeschlossen' &&
                    migration.status != 'fehler')
                  _StatusActionButton(
                    currentStatus: migration.status,
                    onStatusChanged: (newStatus, fortschritt) {
                      onStatusChanged(migration.id, newStatus, fortschritt);
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _typIcon(String typ) {
    switch (typ) {
      case 'excel':
        return Icons.table_chart;
      case 'papier':
        return Icons.description;
      case 'datenbank':
        return Icons.storage;
      case 'andere':
        return Icons.folder;
      default:
        return Icons.folder;
    }
  }

  Color _typColor(String typ) {
    switch (typ) {
      case 'excel':
        return AppStatusColors.success;
      case 'papier':
        return AppStatusColors.warning;
      case 'datenbank':
        return AppStatusColors.info;
      case 'andere':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF7C3AED);
    }
  }
}

// ─── Status Badge ───

class _StatusBadge extends StatelessWidget {
  final String status;
  final String label;

  const _StatusBadge({required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
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
        return AppStatusColors.info;
    }
  }
}

// ─── Status Action Button (Quick Transition) ───

class _StatusActionButton extends StatelessWidget {
  final String currentStatus;
  final void Function(String newStatus, int fortschritt) onStatusChanged;

  const _StatusActionButton({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      tooltip: 'Status aendern',
      onSelected: (value) {
        switch (value) {
          case 'in_bearbeitung':
            onStatusChanged('in_bearbeitung', 0);
            break;
          case 'abgeschlossen':
            onStatusChanged('abgeschlossen', 100);
            break;
          case 'fehler':
            onStatusChanged('fehler', 0);
            break;
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (currentStatus == 'geplant') {
          items.add(
            PopupMenuItem(
              value: 'in_bearbeitung',
              child: Row(
                children: [
                  Icon(Icons.play_arrow,
                      size: 18, color: AppStatusColors.warning),
                  const SizedBox(width: 8),
                  const Text('Starten'),
                ],
              ),
            ),
          );
        }

        if (currentStatus == 'in_bearbeitung') {
          items.add(
            PopupMenuItem(
              value: 'abgeschlossen',
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 18, color: AppStatusColors.success),
                  const SizedBox(width: 8),
                  const Text('Abschliessen'),
                ],
              ),
            ),
          );
        }

        if (currentStatus == 'geplant' ||
            currentStatus == 'in_bearbeitung') {
          items.add(
            PopupMenuItem(
              value: 'fehler',
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 18, color: AppStatusColors.error),
                  const SizedBox(width: 8),
                  const Text('Fehler melden'),
                ],
              ),
            ),
          );
        }

        return items;
      },
    );
  }
}
