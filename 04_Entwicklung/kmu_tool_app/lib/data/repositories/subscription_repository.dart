import 'package:kmu_tool_app/data/models/subscription_plan.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class SubscriptionRepository {
  /// Alle aktiven Pläne laden (sortiert).
  static Future<List<SubscriptionPlan>> getPlans() async {
    final response = await SupabaseService.client
        .from('subscription_plans')
        .select()
        .eq('aktiv', true)
        .order('sort_order');

    return (response as List)
        .map((json) => SubscriptionPlan.fromJson(json))
        .toList();
  }

  /// Plan des aktuellen Users wechseln.
  static Future<void> changePlan(String planId) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    await SupabaseService.client.from('user_subscriptions').upsert({
      'user_id': userId,
      'plan_id': planId,
      'status': 'active',
      'gueltig_ab': DateTime.now().toIso8601String().split('T').first,
    }, onConflict: 'user_id');
  }
}
