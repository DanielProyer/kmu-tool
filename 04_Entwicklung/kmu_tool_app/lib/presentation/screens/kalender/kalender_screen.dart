import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kmu_tool_app/presentation/providers/termin_provider.dart';
import 'package:kmu_tool_app/data/models/termin.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';

class KalenderScreen extends ConsumerStatefulWidget {
  const KalenderScreen({super.key});

  @override
  ConsumerState<KalenderScreen> createState() => _KalenderScreenState();
}

class _KalenderScreenState extends ConsumerState<KalenderScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final _dateFormat = DateFormat('dd.MM.yyyy');

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Termine fuer den aktuellen Monat laden
    final monatsTermineAsync = ref.watch(
      termineByMonatProvider(_focusedDay),
    );

    // Termine fuer den ausgewaehlten Tag laden
    final tagesTermineAsync = ref.watch(
      termineByDatumProvider(_selectedDay),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: const Text('Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Heute',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Neuer Termin',
            onPressed: () async {
              await context.push('/kalender/neu');
              _invalidateProviders();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Kalender ───
          monatsTermineAsync.when(
            loading: () => _buildCalendar(context, []),
            error: (_, __) => _buildCalendar(context, []),
            data: (termine) => _buildCalendar(context, termine),
          ),

          const Divider(height: 1),

          // ─── Tages-Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.event_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  _dateFormat.format(_selectedDay),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // ─── Termin-Liste fuer ausgewaehlten Tag ───
          Expanded(
            child: tagesTermineAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
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
                        style:
                            TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(
                            termineByDatumProvider(_selectedDay)),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (termine) {
                if (termine.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.event_busy_outlined,
                            size: 48,
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Keine Termine an diesem Tag',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _invalidateProviders();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: termine.length,
                    itemBuilder: (context, index) {
                      final termin = termine[index];
                      return _TerminCard(
                        termin: termin,
                        onTap: () async {
                          await context.push('/kalender/${termin.id}');
                          _invalidateProviders();
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
          await context.push('/kalender/neu');
          _invalidateProviders();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context, List<Termin> termine) {
    final colorScheme = Theme.of(context).colorScheme;

    // Termine nach Datum gruppieren
    final Map<DateTime, List<Termin>> termineByDate = {};
    for (final termin in termine) {
      final key = DateTime(
        termin.datum.year,
        termin.datum.month,
        termin.datum.day,
      );
      termineByDate.putIfAbsent(key, () => []).add(termin);
    }

    return TableCalendar<Termin>(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2099, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      startingDayOfWeek: StartingDayOfWeek.monday,
      locale: 'de_DE',
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: (day) {
        final key = DateTime(day.year, day.month, day.day);
        return termineByDate[key] ?? [];
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      onFormatChanged: (format) {
        setState(() {
          _calendarFormat = format;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        // Heute
        todayDecoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        // Ausgewaehlt
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        // Marker (Dots unter dem Datum)
        markerDecoration: BoxDecoration(
          color: colorScheme.secondary,
          shape: BoxShape.circle,
        ),
        markerSize: 6,
        markersMaxCount: 3,
        markerMargin: const EdgeInsets.symmetric(horizontal: 1),
        // Wochenende
        weekendTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
        // Ausserhalb des Monats
        outsideDaysVisible: false,
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: true,
        titleCentered: true,
        formatButtonDecoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        formatButtonTextStyle: TextStyle(
          fontSize: 13,
          color: colorScheme.onSurfaceVariant,
        ),
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: colorScheme.onSurfaceVariant,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
        weekendStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  void _invalidateProviders() {
    ref.invalidate(termineByMonatProvider(_focusedDay));
    ref.invalidate(termineByDatumProvider(_selectedDay));
  }
}

// ─── Termin Card ───

class _TerminCard extends StatelessWidget {
  final Termin termin;
  final VoidCallback onTap;

  const _TerminCard({
    required this.termin,
    required this.onTap,
  });

  Color _typColor(String typ) {
    switch (typ) {
      case 'termin':
        return AppStatusColors.info;
      case 'auftrag':
        return AppStatusColors.warning;
      case 'service':
        return AppStatusColors.success;
      case 'erinnerung':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'geplant':
        return AppStatusColors.offen;
      case 'bestaetigt':
        return AppStatusColors.info;
      case 'erledigt':
        return AppStatusColors.abgeschlossen;
      case 'abgesagt':
        return AppStatusColors.storniert;
      default:
        return AppStatusColors.storniert;
    }
  }

  IconData _typIcon(String typ) {
    switch (typ) {
      case 'termin':
        return Icons.event_outlined;
      case 'auftrag':
        return Icons.work_outline;
      case 'service':
        return Icons.build_outlined;
      case 'erinnerung':
        return Icons.notifications_outlined;
      default:
        return Icons.event_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final typColor = _typColor(termin.typ);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: typColor.withValues(alpha: 0.1),
                child: Icon(
                  _typIcon(termin.typ),
                  color: typColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titel + Badges
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            termin.titel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Typ Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            termin.typLabel,
                            style: TextStyle(
                              color: typColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Zeit + Status
                    Row(
                      children: [
                        if (termin.zeitAnzeige.isNotEmpty) ...[
                          Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            termin.zeitAnzeige,
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _statusColor(termin.status)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            termin.statusLabel,
                            style: TextStyle(
                              color: _statusColor(termin.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Kunde
                    if (termin.kundeBezeichnung != null &&
                        termin.kundeBezeichnung!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              termin.kundeBezeichnung!,
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
                    ],
                  ],
                ),
              ),
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
