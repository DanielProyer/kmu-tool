import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/local/kunde_local_export.dart';
import 'package:kmu_tool_app/data/local/kunde_kontakt_local_export.dart';
import 'package:kmu_tool_app/data/local/offerte_local_export.dart';
import 'package:kmu_tool_app/data/local/offert_position_local_export.dart';
import 'package:kmu_tool_app/data/local/auftrag_local_export.dart';
import 'package:kmu_tool_app/data/local/zeiterfassung_local_export.dart';
import 'package:kmu_tool_app/data/local/rapport_local_export.dart';
import 'package:kmu_tool_app/data/repositories/kunde_repository.dart';
import 'package:kmu_tool_app/data/repositories/kunde_kontakt_repository.dart';
import 'package:kmu_tool_app/data/repositories/offerte_repository.dart';
import 'package:kmu_tool_app/data/repositories/offert_position_repository.dart';
import 'package:kmu_tool_app/data/repositories/auftrag_repository.dart';
import 'package:kmu_tool_app/data/repositories/zeiterfassung_repository.dart';
import 'package:kmu_tool_app/data/repositories/rapport_repository.dart';
import 'package:kmu_tool_app/data/local/artikel_local_export.dart';
import 'package:kmu_tool_app/data/repositories/artikel_repository.dart';
import 'package:kmu_tool_app/data/models/lagerort.dart';
import 'package:kmu_tool_app/data/models/lieferant.dart';
import 'package:kmu_tool_app/data/models/artikel_lieferant.dart';
import 'package:kmu_tool_app/data/models/artikel_foto.dart';
import 'package:kmu_tool_app/data/models/lagerbestand.dart';
import 'package:kmu_tool_app/data/models/lagerbewegung.dart';
import 'package:kmu_tool_app/data/repositories/lagerort_repository.dart';
import 'package:kmu_tool_app/data/repositories/lieferant_repository.dart';
import 'package:kmu_tool_app/data/repositories/artikel_lieferant_repository.dart';
import 'package:kmu_tool_app/data/repositories/artikel_foto_repository.dart';
import 'package:kmu_tool_app/data/repositories/lagerbestand_repository.dart';
import 'package:kmu_tool_app/data/repositories/lagerbewegung_repository.dart';

// ─── Kunden ───

final kundenListProvider =
    AsyncNotifierProvider<KundenListNotifier, List<KundeLocal>>(
  KundenListNotifier.new,
);

class KundenListNotifier extends AsyncNotifier<List<KundeLocal>> {
  @override
  Future<List<KundeLocal>> build() async {
    return KundeRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => KundeRepository.getAll());
  }
}

final kundeProvider =
    AsyncNotifierProvider.family<KundeNotifier, KundeLocal?, String>(
  KundeNotifier.new,
);

class KundeNotifier extends FamilyAsyncNotifier<KundeLocal?, String> {
  @override
  Future<KundeLocal?> build(String arg) async {
    return KundeRepository.getById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => KundeRepository.getById(arg));
  }
}

// ─── Kunde Kontakte ───

final kundeKontakteProvider = AsyncNotifierProvider.family<
    KundeKontakteNotifier, List<KundeKontaktLocal>, String>(
  KundeKontakteNotifier.new,
);

class KundeKontakteNotifier
    extends FamilyAsyncNotifier<List<KundeKontaktLocal>, String> {
  @override
  Future<List<KundeKontaktLocal>> build(String arg) async {
    return KundeKontaktRepository.getByKunde(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => KundeKontaktRepository.getByKunde(arg));
  }
}

final kundeKontaktProvider = AsyncNotifierProvider.family<
    KundeKontaktNotifier, KundeKontaktLocal?, String>(
  KundeKontaktNotifier.new,
);

class KundeKontaktNotifier
    extends FamilyAsyncNotifier<KundeKontaktLocal?, String> {
  @override
  Future<KundeKontaktLocal?> build(String arg) async {
    return null;
  }
}

// ─── Offerten ───

final offertenListProvider =
    AsyncNotifierProvider<OffertenListNotifier, List<OfferteLocal>>(
  OffertenListNotifier.new,
);

class OffertenListNotifier extends AsyncNotifier<List<OfferteLocal>> {
  @override
  Future<List<OfferteLocal>> build() async {
    return OfferteRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => OfferteRepository.getAll());
  }
}

final offerteProvider =
    AsyncNotifierProvider.family<OfferteNotifier, OfferteLocal?, String>(
  OfferteNotifier.new,
);

class OfferteNotifier extends FamilyAsyncNotifier<OfferteLocal?, String> {
  @override
  Future<OfferteLocal?> build(String arg) async {
    return OfferteRepository.getById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => OfferteRepository.getById(arg));
  }
}

final offertenByKundeProvider = AsyncNotifierProvider.family<
    OffertenByKundeNotifier, List<OfferteLocal>, String>(
  OffertenByKundeNotifier.new,
);

class OffertenByKundeNotifier
    extends FamilyAsyncNotifier<List<OfferteLocal>, String> {
  @override
  Future<List<OfferteLocal>> build(String arg) async {
    return OfferteRepository.getByKunde(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => OfferteRepository.getByKunde(arg));
  }
}

// ─── Offert-Positionen ───

final offertPositionenProvider = AsyncNotifierProvider.family<
    OffertPositionenNotifier, List<OffertPositionLocal>, String>(
  OffertPositionenNotifier.new,
);

class OffertPositionenNotifier
    extends FamilyAsyncNotifier<List<OffertPositionLocal>, String> {
  @override
  Future<List<OffertPositionLocal>> build(String arg) async {
    return OffertPositionRepository.getByOfferte(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => OffertPositionRepository.getByOfferte(arg));
  }
}

// ─── Aufträge ───

final auftraegeListProvider =
    AsyncNotifierProvider<AuftraegeListNotifier, List<AuftragLocal>>(
  AuftraegeListNotifier.new,
);

class AuftraegeListNotifier extends AsyncNotifier<List<AuftragLocal>> {
  @override
  Future<List<AuftragLocal>> build() async {
    return AuftragRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => AuftragRepository.getAll());
  }
}

final auftragProvider =
    AsyncNotifierProvider.family<AuftragNotifier, AuftragLocal?, String>(
  AuftragNotifier.new,
);

class AuftragNotifier extends FamilyAsyncNotifier<AuftragLocal?, String> {
  @override
  Future<AuftragLocal?> build(String arg) async {
    return AuftragRepository.getById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => AuftragRepository.getById(arg));
  }
}

final auftraegeByKundeProvider = AsyncNotifierProvider.family<
    AuftraegeByKundeNotifier, List<AuftragLocal>, String>(
  AuftraegeByKundeNotifier.new,
);

class AuftraegeByKundeNotifier
    extends FamilyAsyncNotifier<List<AuftragLocal>, String> {
  @override
  Future<List<AuftragLocal>> build(String arg) async {
    return AuftragRepository.getByKunde(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => AuftragRepository.getByKunde(arg));
  }
}

final auftraegeByOfferteProvider = AsyncNotifierProvider.family<
    AuftraegeByOfferteNotifier, List<AuftragLocal>, String>(
  AuftraegeByOfferteNotifier.new,
);

class AuftraegeByOfferteNotifier
    extends FamilyAsyncNotifier<List<AuftragLocal>, String> {
  @override
  Future<List<AuftragLocal>> build(String arg) async {
    return AuftragRepository.getByOfferte(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => AuftragRepository.getByOfferte(arg));
  }
}

// ─── Artikel (Materialstamm) ───

final artikelListProvider =
    AsyncNotifierProvider<ArtikelListNotifier, List<ArtikelLocal>>(
  ArtikelListNotifier.new,
);

class ArtikelListNotifier extends AsyncNotifier<List<ArtikelLocal>> {
  @override
  Future<List<ArtikelLocal>> build() async {
    return ArtikelRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ArtikelRepository.getAll());
  }
}

final artikelProvider =
    AsyncNotifierProvider.family<ArtikelNotifier, ArtikelLocal?, String>(
  ArtikelNotifier.new,
);

class ArtikelNotifier extends FamilyAsyncNotifier<ArtikelLocal?, String> {
  @override
  Future<ArtikelLocal?> build(String arg) async {
    return ArtikelRepository.getById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ArtikelRepository.getById(arg));
  }
}

final artikelSearchProvider =
    FutureProvider.family<List<ArtikelLocal>, String>((ref, query) async {
  if (query.isEmpty) return ArtikelRepository.getAll();
  return ArtikelRepository.search(query);
});

// ─── Lagerorte ───

final lagerortListProvider =
    AsyncNotifierProvider<LagerortListNotifier, List<Lagerort>>(
  LagerortListNotifier.new,
);

class LagerortListNotifier extends AsyncNotifier<List<Lagerort>> {
  @override
  Future<List<Lagerort>> build() async {
    return LagerortRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LagerortRepository.getAll());
  }
}

// ─── Lieferanten ───

final lieferantenListProvider =
    AsyncNotifierProvider<LieferantenListNotifier, List<Lieferant>>(
  LieferantenListNotifier.new,
);

class LieferantenListNotifier extends AsyncNotifier<List<Lieferant>> {
  @override
  Future<List<Lieferant>> build() async {
    return LieferantRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LieferantRepository.getAll());
  }
}

final lieferantProvider =
    AsyncNotifierProvider.family<LieferantNotifier, Lieferant?, String>(
  LieferantNotifier.new,
);

class LieferantNotifier extends FamilyAsyncNotifier<Lieferant?, String> {
  @override
  Future<Lieferant?> build(String arg) async {
    return LieferantRepository.getById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => LieferantRepository.getById(arg));
  }
}

// ─── Artikel-Lieferanten ───

final artikelLieferantenProvider = AsyncNotifierProvider.family<
    ArtikelLieferantenNotifier, List<ArtikelLieferant>, String>(
  ArtikelLieferantenNotifier.new,
);

class ArtikelLieferantenNotifier
    extends FamilyAsyncNotifier<List<ArtikelLieferant>, String> {
  @override
  Future<List<ArtikelLieferant>> build(String arg) async {
    return ArtikelLieferantRepository.getByArtikel(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ArtikelLieferantRepository.getByArtikel(arg));
  }
}

// ─── Artikel-Fotos ───

final artikelFotosProvider = AsyncNotifierProvider.family<
    ArtikelFotosNotifier, List<ArtikelFoto>, String>(
  ArtikelFotosNotifier.new,
);

class ArtikelFotosNotifier
    extends FamilyAsyncNotifier<List<ArtikelFoto>, String> {
  @override
  Future<List<ArtikelFoto>> build(String arg) async {
    return ArtikelFotoRepository.getByArtikel(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => ArtikelFotoRepository.getByArtikel(arg));
  }
}

// ─── Lagerbestände ───

final lagerbestandByArtikelProvider = AsyncNotifierProvider.family<
    LagerbestandByArtikelNotifier, List<Lagerbestand>, String>(
  LagerbestandByArtikelNotifier.new,
);

class LagerbestandByArtikelNotifier
    extends FamilyAsyncNotifier<List<Lagerbestand>, String> {
  @override
  Future<List<Lagerbestand>> build(String arg) async {
    return LagerbestandRepository.getByArtikel(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => LagerbestandRepository.getByArtikel(arg));
  }
}

// ─── Lagerbewegungen ───

final lagerbewegungByArtikelProvider = AsyncNotifierProvider.family<
    LagerbewegungByArtikelNotifier, List<Lagerbewegung>, String>(
  LagerbewegungByArtikelNotifier.new,
);

class LagerbewegungByArtikelNotifier
    extends FamilyAsyncNotifier<List<Lagerbewegung>, String> {
  @override
  Future<List<Lagerbewegung>> build(String arg) async {
    return LagerbewegungRepository.getByArtikel(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => LagerbewegungRepository.getByArtikel(arg));
  }
}

// ─── Zeiterfassungen ───

final zeiterfassungenByAuftragProvider = AsyncNotifierProvider.family<
    ZeiterfassungenByAuftragNotifier, List<ZeiterfassungLocal>, String>(
  ZeiterfassungenByAuftragNotifier.new,
);

class ZeiterfassungenByAuftragNotifier
    extends FamilyAsyncNotifier<List<ZeiterfassungLocal>, String> {
  @override
  Future<List<ZeiterfassungLocal>> build(String arg) async {
    return ZeiterfassungRepository.getByAuftrag(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => ZeiterfassungRepository.getByAuftrag(arg));
  }
}

// ─── Rapporte ───

final rapporteByAuftragProvider = AsyncNotifierProvider.family<
    RapporteByAuftragNotifier, List<RapportLocal>, String>(
  RapporteByAuftragNotifier.new,
);

class RapporteByAuftragNotifier
    extends FamilyAsyncNotifier<List<RapportLocal>, String> {
  @override
  Future<List<RapportLocal>> build(String arg) async {
    return RapportRepository.getByAuftrag(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => RapportRepository.getByAuftrag(arg));
  }
}
