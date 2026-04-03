import '../../../services/supabase/supabase_service.dart';
import '../../models/admin/admin_kundenprofil.dart';

class AdminKundenprofilRepository {
  static const _table = 'admin_kundenprofile';

  static Future<List<AdminKundenprofil>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, user_subscriptions(plan_id, subscription_plans(bezeichnung))')
        .order('firma_name');
    return data.map((json) => AdminKundenprofil.fromJson(json)).toList();
  }

  static Future<List<AdminKundenprofil>> getByStatus(String status) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, user_subscriptions(plan_id, subscription_plans(bezeichnung))')
        .eq('status', status)
        .order('firma_name');
    return data.map((json) => AdminKundenprofil.fromJson(json)).toList();
  }

  static Future<AdminKundenprofil?> getById(String id) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, user_subscriptions(plan_id, subscription_plans(bezeichnung))')
        .eq('id', id)
        .maybeSingle();
    return data != null ? AdminKundenprofil.fromJson(data) : null;
  }

  static Future<List<AdminKundenprofil>> search(String query) async {
    final data = await SupabaseService.client
        .from(_table)
        .select('*, user_subscriptions(plan_id, subscription_plans(bezeichnung))')
        .or('firma_name.ilike.%$query%,kontaktperson.ilike.%$query%,email.ilike.%$query%')
        .order('firma_name')
        .limit(30);
    return data.map((json) => AdminKundenprofil.fromJson(json)).toList();
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
