import '../../services/supabase/supabase_service.dart';
import '../models/rechnungs_position.dart';

class RechnungsPositionRepository {
  static const _table = 'rechnungs_positionen';

  Future<List<RechnungsPosition>> getByRechnung(String rechnungId) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('rechnung_id', rechnungId)
        .order('position_nr', ascending: true);
    return data.map((json) => RechnungsPosition.fromJson(json)).toList();
  }

  Future<void> save(RechnungsPosition position) async {
    await SupabaseService.client.from(_table).upsert(position.toJson());
  }

  Future<void> delete(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  /// Replaces all positions for a given Rechnung.
  /// Deletes existing positions and inserts the new list.
  Future<void> saveAll(
    String rechnungId,
    List<RechnungsPosition> positionen,
  ) async {
    // Delete existing positions for this Rechnung
    await SupabaseService.client
        .from(_table)
        .delete()
        .eq('rechnung_id', rechnungId);

    // Insert all new positions
    if (positionen.isNotEmpty) {
      final rows = positionen.map((p) => p.toJson()).toList();
      await SupabaseService.client.from(_table).insert(rows);
    }
  }
}
