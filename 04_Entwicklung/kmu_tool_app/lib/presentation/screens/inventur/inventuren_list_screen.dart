import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/inventur.dart';
import 'package:kmu_tool_app/presentation/providers/providers.dart';
import 'package:kmu_tool_app/services/lager/inventur_service.dart';

class InventurenListScreen extends ConsumerStatefulWidget {
  const InventurenListScreen({super.key});

  @override
  ConsumerState<InventurenListScreen> createState() =>
      _InventurenListScreenState();
}

class _InventurenListScreenState extends ConsumerState<InventurenListScreen> {
  String _selectedStatus = 'alle';

  final _dateFormat = DateFormat('dd.MM.yyyy');

  List<Inventur> _filterInventuren(List<Inventur> inventuren) {
    if (_selectedStatus == 'alle') return inventuren;
    return inventuren.where((i) => i.status == _selectedStatus).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'geplant':
        return AppStatusColors.storniert;
      case 'aktiv':
        return AppStatusColors.info;
      case 'abgeschlossen':
        return AppStatusColors.success;
      default:
        return AppStatusColors.storniert;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'geplant':
        return Icons.schedule_outlined;
      case 'aktiv':
        return Icons.play_circle_outline;
      case 'abgeschlossen':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _showCreateDialog() async {
    final bezeichnungController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? selectedLagerortId;
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final colorScheme = Theme.of(ctx).colorScheme;
            final lagerorteAsync = ref.watch(lagerortListProvider);

            return AlertDialog(
              title: const Text('Neue Inventur'),
              content: SizedBox(
                width: double.maxFinite,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bezeichnung
                      TextFormField(
                        controller: bezeichnungController,
                        decoration: const InputDecoration(
                          labelText: 'Bezeichnung',
                          hintText: 'z.B. Jahresinventur 2026',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bezeichnung ist erforderlich';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Stichtag
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            locale: const Locale('de', 'CH'),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Stichtag',
                            suffixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            _dateFormat.format(selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lagerort (optional)
                      lagerorteAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => Text(
                          'Lagerorte konnten nicht geladen werden',
                          style: TextStyle(
                            color: AppStatusColors.error,
                            fontSize: 13,
                          ),
                        ),
                        data: (lagerorte) {
                          return DropdownButtonFormField<String?>(
                            value: selectedLagerortId,
                            decoration: const InputDecoration(
                              labelText: 'Lagerort (optional)',
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Alle Lagerorte'),
                              ),
                              ...lagerorte.map((l) => DropdownMenuItem<String?>(
                                    value: l.id,
                                    child: Text(l.bezeichnung),
                                  )),
                            ],
                            onChanged: (value) {
                              setDialogState(
                                  () => selectedLagerortId = value);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isCreating ? null : () => Navigator.of(ctx).pop(null),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: isCreating
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isCreating = true);
                          try {
                            final inventurId =
                                await InventurService.createInventur(
                              bezeichnung: bezeichnungController.text.trim(),
                              stichtag: selectedDate,
                              lagerortId: selectedLagerortId,
                            );
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop(inventurId);
                            }
                          } catch (e) {
                            setDialogState(() => isCreating = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text('Fehler: $e'),
                                  backgroundColor: AppStatusColors.error,
                                ),
                              );
                            }
                          }
                        },
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      ref.invalidate(inventurenListProvider);
      context.push('/inventur/$result');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final inventurenAsync = ref.watch(inventurenListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Inventur'),
      ),
      body: inventurenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
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
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(inventurenListProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
        data: (inventuren) {
          if (inventuren.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.checklist_outlined,
                      size: 72,
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine Inventur erfasst',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Erstelle deine erste Inventur mit dem + Button',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          final filtered = _filterInventuren(inventuren);

          return Column(
            children: [
              // ─── Filter Chips ───
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Alle',
                      isSelected: _selectedStatus == 'alle',
                      onSelected: () =>
                          setState(() => _selectedStatus = 'alle'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Geplant',
                      isSelected: _selectedStatus == 'geplant',
                      onSelected: () =>
                          setState(() => _selectedStatus = 'geplant'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Aktiv',
                      isSelected: _selectedStatus == 'aktiv',
                      onSelected: () =>
                          setState(() => _selectedStatus = 'aktiv'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Abgeschlossen',
                      isSelected: _selectedStatus == 'abgeschlossen',
                      onSelected: () =>
                          setState(() => _selectedStatus = 'abgeschlossen'),
                    ),
                  ],
                ),
              ),

              // ─── Liste ───
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Keine Inventuren mit diesem Status',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(inventurenListProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 4, bottom: 88),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final inventur = filtered[index];
                            return _InventurCard(
                              inventur: inventur,
                              dateFormat: _dateFormat,
                              statusColor: _statusColor(inventur.status),
                              statusIcon: _statusIcon(inventur.status),
                              onTap: () async {
                                await context
                                    .push('/inventur/${inventur.id}');
                                ref.invalidate(inventurenListProvider);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── Filter Chip ───

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: colorScheme.primary.withValues(alpha: 0.15),
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        color:
            isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}

// ─── Inventur Card ───

class _InventurCard extends StatelessWidget {
  final Inventur inventur;
  final DateFormat dateFormat;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;

  const _InventurCard({
    required this.inventur,
    required this.dateFormat,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gesamt = inventur.positionenGesamt ?? 0;
    final gezaehlt = inventur.positionenGezaehlt ?? 0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bezeichnung + Status-Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inventur.bezeichnung,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            inventur.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Stichtag + Lagerort
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(inventur.stichtag),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.warehouse_outlined,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            inventur.lagerortBezeichnung ?? 'Alle Lagerorte',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Progress bar
                    if (gesamt > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: inventur.fortschritt,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                color: statusColor,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$gezaehlt / $gesamt',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
