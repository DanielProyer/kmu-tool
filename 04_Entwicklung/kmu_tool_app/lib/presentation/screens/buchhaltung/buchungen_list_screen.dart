import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/buchung.dart';
import 'package:kmu_tool_app/data/repositories/buchung_repository.dart';
import 'package:kmu_tool_app/data/repositories/konto_repository.dart';

// ─── Providers ───

/// Provider for all buchungen; optionally filters by konto if param is set.
final _buchungenProvider =
    FutureProvider.family<List<Buchung>, int?>((ref, filterKonto) async {
  final repo = BuchungRepository();
  if (filterKonto != null) {
    return repo.getByKonto(filterKonto);
  }
  return repo.getAll();
});

/// Provider for a kontonummer → bezeichnung lookup map.
final _kontenMapProvider =
    FutureProvider<Map<int, String>>((ref) async {
  try {
    final konten = await KontoRepository().getAll();
    return {for (final k in konten) k.kontonummer: k.bezeichnung};
  } catch (_) {
    return {};
  }
});

// ─── Screen ───

class BuchungenListScreen extends ConsumerStatefulWidget {
  final int? filterKontonummer;

  const BuchungenListScreen({super.key, this.filterKontonummer});

  @override
  ConsumerState<BuchungenListScreen> createState() =>
      _BuchungenListScreenState();
}

class _BuchungenListScreenState extends ConsumerState<BuchungenListScreen> {
  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );
  static final _dateFmt = DateFormat('dd.MM.yyyy', 'de_CH');

  /// Currently selected month (1-12), or null = all months
  int? _selectedMonth;

  /// Currently selected year
  int _selectedYear = DateTime.now().year;

  static const _monthNames = [
    'Alle',
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

  List<Buchung> _filterByMonth(List<Buchung> buchungen) {
    if (_selectedMonth == null) return buchungen;
    return buchungen.where((b) {
      return b.datum.year == _selectedYear && b.datum.month == _selectedMonth;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final buchungenAsync =
        ref.watch(_buchungenProvider(widget.filterKontonummer));
    final kontenMapAsync = ref.watch(_kontenMapProvider);

    final kontenMap = kontenMapAsync.valueOrNull ?? {};

    final filterLabel = widget.filterKontonummer != null
        ? 'Konto ${widget.filterKontonummer}'
        : null;
    final kontoName = widget.filterKontonummer != null
        ? kontenMap[widget.filterKontonummer]
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.canPop(context)
              ? context.pop()
              : context.go('/'),
        ),
        title: Text(
          filterLabel != null
              ? 'Journal - ${kontoName ?? filterLabel}'
              : 'Journal',
        ),
      ),
      body: Column(
        children: [
          // ── Month selector ──
          _buildMonthSelector(context),

          // ── Buchungen list ──
          Expanded(
            child: buchungenAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildError(context, error),
              data: (buchungen) {
                final filtered = _filterByMonth(buchungen);
                return _buildList(context, filtered, kontenMap);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/buchhaltung/buchungen/neu');
          ref.invalidate(_buchungenProvider(widget.filterKontonummer));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _monthNames.length,
        itemBuilder: (context, index) {
          final isSelected =
              (index == 0 && _selectedMonth == null) ||
              (index > 0 && _selectedMonth == index);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                index == 0 ? _monthNames[0] : _monthNames[index],
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surfaceCard,
              side: const BorderSide(color: AppColors.divider),
              onSelected: (_) {
                setState(() {
                  _selectedMonth = index == 0 ? null : index;
                });
              },
            ),
          );
        },
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
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Buchung> buchungen,
    Map<int, String> kontenMap,
  ) {
    if (buchungen.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book,
                size: 72,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedMonth != null
                    ? 'Keine Buchungen im ${_monthNames[_selectedMonth!]}'
                    : 'Noch keine Buchungen vorhanden',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_buchungenProvider(widget.filterKontonummer));
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 4, bottom: 88),
        itemCount: buchungen.length,
        itemBuilder: (context, index) {
          final buchung = buchungen[index];
          return _BuchungCard(
            buchung: buchung,
            kontenMap: kontenMap,
            formatCHF: _chf.format,
            formatDate: _dateFmt.format,
            onTap: () => _showBuchungDetail(context, buchung, kontenMap),
          );
        },
      ),
    );
  }

  void _showBuchungDetail(
    BuildContext context,
    Buchung buchung,
    Map<int, String> kontenMap,
  ) {
    final sollName = kontenMap[buchung.sollKonto] ?? '';
    final habenName = kontenMap[buchung.habenKonto] ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Buchungsdetail',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),

                _DetailRow('Datum', _dateFmt.format(buchung.datum)),
                _DetailRow('Beschreibung', buchung.beschreibung),
                _DetailRow(
                  'Soll',
                  '${buchung.sollKonto} $sollName',
                ),
                _DetailRow(
                  'Haben',
                  '${buchung.habenKonto} $habenName',
                ),
                _DetailRow('Betrag', _chf.format(buchung.betrag)),
                if (buchung.belegNr != null && buchung.belegNr!.isNotEmpty)
                  _DetailRow('Beleg-Nr.', buchung.belegNr!),
                if (buchung.rechnungId != null)
                  _DetailRow('Rechnung', buchung.rechnungId!),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuchungCard extends StatelessWidget {
  final Buchung buchung;
  final Map<int, String> kontenMap;
  final String Function(num) formatCHF;
  final String Function(DateTime) formatDate;
  final VoidCallback onTap;

  const _BuchungCard({
    required this.buchung,
    required this.kontenMap,
    required this.formatCHF,
    required this.formatDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sollName = kontenMap[buchung.sollKonto] ?? '${buchung.sollKonto}';
    final habenName = kontenMap[buchung.habenKonto] ?? '${buchung.habenKonto}';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: date + amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDate(buchung.datum),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (buchung.belegNr != null && buchung.belegNr!.isNotEmpty)
                    Text(
                      buchung.belegNr!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Beschreibung
              Text(
                buchung.beschreibung,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Soll → Haben + Betrag
              Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: '${buchung.sollKonto}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: sollName),
                          const TextSpan(
                            text: '  an  ',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: '${buchung.habenKonto}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: habenName),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    formatCHF(buchung.betrag),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
