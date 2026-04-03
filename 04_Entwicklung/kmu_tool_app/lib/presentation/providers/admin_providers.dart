import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kmu_tool_app/data/models/admin/admin_kundenprofil.dart';
import 'package:kmu_tool_app/data/models/admin/admin_rechnung.dart';
import 'package:kmu_tool_app/data/models/admin/admin_datenmigration.dart';
import 'package:kmu_tool_app/data/models/admin/admin_dashboard_stats.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_kundenprofil_repository.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_rechnung_repository.dart';
import 'package:kmu_tool_app/data/repositories/admin/admin_datenmigration_repository.dart';
import 'package:kmu_tool_app/services/admin/admin_service.dart';

// ─── Admin Dashboard Stats ───

final adminDashboardProvider =
    FutureProvider<AdminDashboardStats>((ref) async {
  return AdminService.getDashboardStats();
});

// ─── Admin Kundenprofile ───

final adminKundenListProvider = AsyncNotifierProvider<
    AdminKundenListNotifier, List<AdminKundenprofil>>(
  AdminKundenListNotifier.new,
);

class AdminKundenListNotifier
    extends AsyncNotifier<List<AdminKundenprofil>> {
  @override
  Future<List<AdminKundenprofil>> build() async {
    return AdminKundenprofilRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => AdminKundenprofilRepository.getAll());
  }
}

final adminKundeProvider = AsyncNotifierProvider.family<
    AdminKundeNotifier, AdminKundenprofil?, String>(
  AdminKundeNotifier.new,
);

class AdminKundeNotifier
    extends FamilyAsyncNotifier<AdminKundenprofil?, String> {
  @override
  Future<AdminKundenprofil?> build(String arg) async {
    return AdminKundenprofilRepository.getById(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => AdminKundenprofilRepository.getById(arg));
  }
}

final adminKundeStatsProvider = FutureProvider.family<AdminKundeStats, String>(
    (ref, userId) async {
  return AdminService.getKundeStats(userId);
});

// ─── Admin Rechnungen ───

final adminRechnungenListProvider = AsyncNotifierProvider<
    AdminRechnungenListNotifier, List<AdminRechnung>>(
  AdminRechnungenListNotifier.new,
);

class AdminRechnungenListNotifier
    extends AsyncNotifier<List<AdminRechnung>> {
  @override
  Future<List<AdminRechnung>> build() async {
    return AdminRechnungRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state =
        await AsyncValue.guard(() => AdminRechnungRepository.getAll());
  }
}

final adminRechnungenByKundeProvider = AsyncNotifierProvider.family<
    AdminRechnungenByKundeNotifier, List<AdminRechnung>, String>(
  AdminRechnungenByKundeNotifier.new,
);

class AdminRechnungenByKundeNotifier
    extends FamilyAsyncNotifier<List<AdminRechnung>, String> {
  @override
  Future<List<AdminRechnung>> build(String arg) async {
    return AdminRechnungRepository.getByKunde(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => AdminRechnungRepository.getByKunde(arg));
  }
}

// ─── Admin Datenmigrationen ───

final adminMigrationenListProvider = AsyncNotifierProvider<
    AdminMigrationenListNotifier, List<AdminDatenmigration>>(
  AdminMigrationenListNotifier.new,
);

class AdminMigrationenListNotifier
    extends AsyncNotifier<List<AdminDatenmigration>> {
  @override
  Future<List<AdminDatenmigration>> build() async {
    return AdminDatenmigrationRepository.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => AdminDatenmigrationRepository.getAll());
  }
}

final adminMigrationenByKundeProvider = AsyncNotifierProvider.family<
    AdminMigrationenByKundeNotifier, List<AdminDatenmigration>, String>(
  AdminMigrationenByKundeNotifier.new,
);

class AdminMigrationenByKundeNotifier
    extends FamilyAsyncNotifier<List<AdminDatenmigration>, String> {
  @override
  Future<List<AdminDatenmigration>> build(String arg) async {
    return AdminDatenmigrationRepository.getByKunde(arg);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
        () => AdminDatenmigrationRepository.getByKunde(arg));
  }
}
