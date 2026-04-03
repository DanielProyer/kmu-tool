import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/data/repositories/offerte_repository.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_repository.dart';
import 'package:kmu_tool_app/data/repositories/rechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/artikel_repository.dart';

class DashboardData {
  final int kundenCount;
  final int offeneOffertenCount;
  final int aktiveAuftraegeCount;
  final double offeneRechnungenBetrag;
  final int artikelCount;

  const DashboardData({
    this.kundenCount = 0,
    this.offeneOffertenCount = 0,
    this.aktiveAuftraegeCount = 0,
    this.offeneRechnungenBetrag = 0,
    this.artikelCount = 0,
  });
}

/// Loads summary data for the dashboard tiles.
///
/// Uses the existing static repositories for Kunden, Offerten, and Auftraege
/// (Isar/Supabase-aware), and the instance-based RechnungRepository for
/// Rechnungen (Supabase-only).
final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  try {
    // Parallel fetch of all counts
    final results = await Future.wait([
      KundeRepository.count(),
      OfferteRepository.getByStatus('offen')
          .then((list) => list.length),
      AuftragRepository.getByStatus('in_bearbeitung')
          .then((list) => list.length),
      RechnungRepository().summeOffene(),
      ArtikelRepository.getAll().then((list) => list.length),
    ]);

    return DashboardData(
      kundenCount: results[0] as int,
      offeneOffertenCount: results[1] as int,
      aktiveAuftraegeCount: results[2] as int,
      offeneRechnungenBetrag: results[3] as double,
      artikelCount: results[4] as int,
    );
  } catch (_) {
    // Return zeroed data if any repo call fails (e.g. offline + web mode)
    return const DashboardData();
  }
});
