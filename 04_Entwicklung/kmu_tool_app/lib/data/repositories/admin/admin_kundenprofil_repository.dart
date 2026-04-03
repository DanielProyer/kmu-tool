import '../../../services/supabase/supabase_service.dart';
import '../../models/admin/admin_kundenprofil.dart';

class AdminKundenprofilRepository {
  static const _table = 'admin_kundenprofile';

  /// Plan-Info separat laden und in JSON einfuegen.
  static Future<Map<String, dynamic>> _enrichWithPlan(
      Map<String, dynamic> json) async {
    final userId = json['user_id'] as String?;
    if (userId != null) {
      try {
        final sub = await SupabaseService.client
            .from('user_subscriptions')
            .select('plan_id, subscription_plans(bezeichnung)')
            .eq('user_id', userId)
            .maybeSingle();
        if (sub != null) {
          json['user_subscriptions'] = sub;
        }
      } catch (_) {
        // Plan-Info ist optional
      }
    }
    return json;
  }

  static Future<List<AdminKundenprofil>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .order('firma_name');
    final enriched =
        await Future.wait(data.map((json) => _enrichWithPlan(json)));
    return enriched.map((json) => AdminKundenprofil.fromJson(json)).toList();
  }

  static Future<List<AdminKundenprofil>> getByStatus(String status) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('status', status)
        .order('firma_name');
    final enriched =
        await Future.wait(data.map((json) => _enrichWithPlan(json)));
    return enriched.map((json) => AdminKundenprofil.fromJson(json)).toList();
  }

  static Future<AdminKundenprofil?> getById(String id) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .maybeSingle();
    if (data == null) return null;
    final enriched = await _enrichWithPlan(data);
    return AdminKundenprofil.fromJson(enriched);
  }

  static Future<List<AdminKundenprofil>> search(String query) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .or('firma_name.ilike.%$query%,kontaktperson.ilike.%$query%,email.ilike.%$query%')
        .order('firma_name')
        .limit(30);
    final enriched =
        await Future.wait(data.map((json) => _enrichWithPlan(json)));
    return enriched.map((json) => AdminKundenprofil.fromJson(json)).toList();
  }

  static Future<void> save(AdminKundenprofil profil) async {
    await SupabaseService.client.from(_table).upsert(profil.toJson());
  }

  static Future<void> updateStatus(String id, String status) async {
    await SupabaseService.client
        .from(_table)
        .update({'status': status}).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await SupabaseService.client.from(_table).delete().eq('id', id);
  }

  static Future<int> count() async {
    final result = await SupabaseService.client
        .from(_table)
        .select()
        .count();
    return result.count;
  }
}
