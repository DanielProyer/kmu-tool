import 'package:kmu_tool_app/data/models/admin/admin_dashboard_stats.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class AdminService {
  static bool _isAdmin = false;
  static bool get isAdmin => _isAdmin;

  static Future<void> checkAdminStatus() async {
    try {
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) {
        _isAdmin = false;
        return;
      }
      final data = await SupabaseService.client
          .from('admin_users')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      _isAdmin = data != null;
    } catch (_) {
      _isAdmin = false;
    }
  }

  static Future<AdminDashboardStats> getDashboardStats() async {
    try {
      final data = await SupabaseService.client
          .rpc('get_admin_dashboard_stats');
      if (data is Map<String, dynamic>) {
        return AdminDashboardStats.fromJson(data);
      }
      return const AdminDashboardStats();
    } catch (_) {
      return const AdminDashboardStats();
    }
  }

  static Future<AdminKundeStats> getKundeStats(String userId) async {
    try {
      final data = await SupabaseService.client
          .rpc('get_kunde_stats', params: {'p_user_id': userId});
      if (data is Map<String, dynamic>) {
        return AdminKundeStats.fromJson(data);
      }
      return const AdminKundeStats();
    } catch (_) {
      return const AdminKundeStats();
    }
  }

  static Future<void> changeKundePlan(
      String userId, String planId) async {
    await SupabaseService.client.from('user_subscriptions').upsert({
      'user_id': userId,
      'plan_id': planId,
      'status': 'active',
      'gueltig_ab': DateTime.now().toIso8601String().split('T').first,
    }, onConflict: 'user_id');
  }

  static Future<void> updateFeatureOverrides(
      String userId, Map<String, dynamic> overrides) async {
    await SupabaseService.client
        .from('user_subscriptions')
        .update({'feature_overrides': overrides}).eq('user_id', userId);
  }

  static void reset() {
    _isAdmin = false;
  }
}
