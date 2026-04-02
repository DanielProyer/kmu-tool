import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kmu_tool_app/core/theme/app_theme.dart';
import 'package:kmu_tool_app/data/models/konto.dart';
import 'package:kmu_tool_app/data/repositories/konto_repository.dart';

// ─── Provider ───

final _kontenProvider = FutureProvider<List<Konto>>((ref) async {
  return KontoRepository().getAll();
});

// ─── Screen ───

class KontenplanScreen extends ConsumerWidget {
  const KontenplanScreen({super.key});

  static final _chf = NumberFormat.currency(
    locale: 'de_CH',
    symbol: 'CHF',
    decimalDigits: 2,
  );

  /// Kontenklassen according to Swiss KMU-Kontenrahmen (OR 957ff.)
  static const _kontenklassen = <int, String>{
    1: 'Aktiven',
    2: 'Passiven',
    3: 'Betrieblicher Ertrag',
    4: 'Materialaufwand',
    5: 'Personalaufwand',
    6: 'Sonstiger Betriebsaufwand',
    8: 'Ausserordentlicher Aufwand / Ertrag',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kontenAsync = ref.watch(_kontenProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontenplan'),
      ),
      body: kontenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildError(context, ref, error),
        data: (konten) => _buildKontenplan(context, konten),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.invalidate(_kontenProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKontenplan(BuildContext context, List<Konto> konten) {
    // Group by kontenklasse
    final grouped = <int, List<Konto>>{};
    for (final konto in konten) {
      grouped.putIfAbsent(konto.kontenklasse, () => []).add(konto);
    }

    // Get the klassen we have data for, sorted
    final klassen = grouped.keys.toList()..sort();

    // If no klassen with data, also show the standard empty ones
    if (klassen.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.list_alt,
                size: 72,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Noch kein Kontenplan vorhanden',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Der Kontenplan wird beim ersten Login automatisch erstellt.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Use context to access WidgetRef – but since this is ConsumerWidget,
        // we rely on the consumer to invalidate. Wrapped in the build method.
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: klassen.length,
        itemBuilder: (context, index) {
          final klasse = klassen[index];
          final kontenInKlasse = grouped[klasse]!;
          final klasseName =
              _kontenklassen[klasse] ?? 'Klasse $klasse';

          // Calculate total saldo for the group
          final totalSaldo =
              kontenInKlasse.fold<double>(0, (sum, k) => sum + k.saldo);

          return _KontenklasseSection(
            klasse: klasse,
            klasseName: klasseName,
            konten: kontenInKlasse,
            totalSaldo: totalSaldo,
            formatCHF: _chf.format,
            initiallyExpanded: index < 3, // Expand first 3 groups
          );
        },
      ),
    );
  }
}

class _KontenklasseSection extends StatelessWidget {
  final int klasse;
  final String klasseName;
  final List<Konto> konten;
  final double totalSaldo;
  final String Function(num) formatCHF;
  final bool initiallyExpanded;

  const _KontenklasseSection({
    required this.klasse,
    required this.klasseName,
    required this.konten,
    required this.totalSaldo,
    required this.formatCHF,
    this.initiallyExpanded = false,
  });

  Color _klasseColor() {
    switch (klasse) {
      case 1:
        return AppColors.primary;
      case 2:
        return const Color(0xFF7C3AED); // Purple
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.secondary;
      case 5:
        return AppColors.warning;
      case 6:
        return AppColors.error;
      case 8:
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _klasseColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$klasse',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          klasseName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          '${konten.length} Konten  |  ${formatCHF(totalSaldo)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        children: konten.map((konto) {
          return _KontoListTile(
            konto: konto,
            formatCHF: formatCHF,
            onTap: () {
              // Navigate to journal filtered by this account
              context.push('/buchhaltung/buchungen', extra: konto.kontonummer);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _KontoListTile extends StatelessWidget {
  final Konto konto;
  final String Function(num) formatCHF;
  final VoidCallback onTap;

  const _KontoListTile({
    required this.konto,
    required this.formatCHF,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final saldoColor = konto.saldo > 0
        ? AppColors.success
        : konto.saldo < 0
            ? AppColors.error
            : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Kontonummer
            SizedBox(
              width: 52,
              child: Text(
                '${konto.kontonummer}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Bezeichnung
            Expanded(
              child: Text(
                konto.bezeichnung,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            // Saldo
            Text(
              formatCHF(konto.saldo),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: saldoColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
